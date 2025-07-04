class Player::MatchesController < Player::BaseController

  before_action :load_and_authorize_record, except: [:create, :toggle_reaction, :switch_prediction]
  after_action :verify_authorized, except: [:create, :toggle_reaction]


  def create
    @requested_player = Player.where(anonymized_at: nil).find params[:player_id]

    unless MatchPolicy.new(current_player, nil).create?(selected_season, @requested_player)
      raise Pundit::NotAuthorizedError, "nie je možné vyzvať hráča #{@requested_player.name}"
    end

    now = Time.now
    @match = selected_season.matches.new(
      requested_at: now,
      published_at: now,
      ranking_counted: true,
      assignments: [
        Assignment.new(player: current_player, side: 1),
        Assignment.new(player: @requested_player, side: 2)
      ]
    )

    current_player.update(cant_play_since: nil)

    if @match.save
      redirect_with_message match_path(@match), 'Výzva bola vytvorená.'
    else
      redirect_with_message player_path(@requested_player), 'Výzvu sa nepodarilo vytvoriť.', :alert
    end
  end


  def edit

  end


  def update
    if @match.update(whitelisted_params)
      @match.assignments.each do |assignment|
        Turbo::StreamsChannel.broadcast_update_to(
          "match_#{@match.id}_for_player_#{assignment.player.id}",
          partial: "matches/match", locals: { match: @match, player: assignment.player, privacy: current_player.blank? },
          target: "match_#{@match.id}"
        )
      end

      redirect_with_message match_path(@match)
    else
      render_with_message :edit
    end
  end


  def destroy
    @match.destroy
    redirect_with_message root_path, 'Výzva/zápas bol odstránený.'
  end


  def accept
    ActiveRecord::Base.transaction do
      @match.update(accepted_at: Time.now)
      @match.players.update_all(open_to_play_since: nil)

      @players_open_to_play = Player.where.not(open_to_play_since: nil)
                                    .order(open_to_play_since: :desc)

      Turbo::StreamsChannel.broadcast_update_to "players_open_to_play",
                                                target: "players_open_to_play",
                                                partial: "shared/players_open_to_play",
                                                locals: { players: @players_open_to_play, signed_in_player: current_player }

      Turbo::StreamsChannel.broadcast_update_to "players_open_to_play",
                                                target: "players_open_to_play_top",
                                                partial: "shared/players_open_to_play",
                                                locals: { players: @players_open_to_play, signed_in_player: current_player }

      @match.assignments.each do |assignment|
        Turbo::StreamsChannel.broadcast_update_to(
          "match_#{@match.id}_for_player_#{assignment.player.id}",
          partial: "matches/match", locals: { match: @match, player: assignment.player, privacy: current_player.blank? },
          target: "match_#{@match.id}"
        )
      end
    end

    redirect_to match_path(@match)
  end


  def reject
    @match.update(rejected_at: Time.now)
    @match.assignments.each do |assignment|
      Turbo::StreamsChannel.broadcast_update_to(
        "match_#{@match.id}_for_player_#{assignment.player.id}",
        partial: "matches/match", locals: { match: @match, player: assignment.player, privacy: current_player.blank? },
        target: "match_#{@match.id}"
      )
    end

    redirect_to match_path(@match)
  end


  def finish_init

  end


  def finish
    @match.finish params.slice(
      "score",
      "retired_player_id",
      "play_date",
      "place_id",
      "notes"
    ).merge("score_side" => @match.assignments.find { |a| a.player_id == current_player.id }.side)

    if @match.finished_at.present? && @match.errors.none?
      @match.assignments.each do |assignment|
        Turbo::StreamsChannel.broadcast_update_to(
          "match_#{@match.id}_for_player_#{assignment.player.id}",
          partial: "matches/match", locals: { match: @match, player: assignment.player, privacy: current_player.blank? },
          target: "match_#{@match.id}"
        )
      end

      redirect_with_message match_path(@match), 'Zápas bol zapísaný, rebríček sa aktualizuje časom.'
    else
      render_with_message :finish_init, 'Zápas sa nepodarilo zapísať.'
    end
  end


  def cancel
    @match.update(canceled_at: Time.now, canceled_by: current_player)
    @match.assignments.each do |assignment|
      Turbo::StreamsChannel.broadcast_update_to(
        "match_#{@match.id}_for_player_#{assignment.player.id}",
        partial: "matches/match", locals: { match: @match, player: assignment.player, privacy: current_player.blank? },
        target: "match_#{@match.id}"
      )
    end

    redirect_with_message match_path(@match), 'Zápas bol zrušený.'
  end


  def toggle_reaction
    @match = Match.published.find(params[:id])
    reaction = Reaction.find_by(reactionable: @match, player: current_player)

    if reaction.present?
      reaction.destroy!
    else
      Reaction.create!(reactionable: @match, player: current_player)
    end

    @match.reload

    # Turbo::StreamsChannel.broadcast_replace_to "matches",
    #                                            target: "match_#{@match.id}_reactions",
    #                                            partial: "shared/reactions_buttons",
    #                                            locals: { reactionable: @match, current_player: current_player }
    # Turbo::StreamsChannel.broadcast_replace_to "matches",
    #                                            target: "tiny_match_#{@match.id}_tiny_reactions",
    #                                            partial: "shared/reactions_buttons_tiny",
    #                                            locals: { reactionable: @match, current_player: current_player }

    render turbo_stream: [
      turbo_stream.replace("match_#{@match.id}_reactions",
                           partial: "shared/reactions_buttons",
                           locals: {
                             reactionable: @match,
                             player: current_player,
                             toggle_reaction_path: toggle_reaction_player_match_path(@match),
                             object_path: match_path(@match)
                           }),
      turbo_stream.replace("tiny_match_#{@match.id}_tiny_reactions",
                           partial: "shared/reactions_buttons_tiny",
                           locals: { reactionable: @match, player: current_player })
    ]
  end


  def switch_prediction
    @match = Match.published.find(params[:id])
    authorize @match

    @prediction = @match.predictions.find_by(player: current_player)

    if @prediction.present?
      if params[:side].to_i == @prediction.side
        @prediction.destroy
      else
        @prediction.update(side: params[:side])
      end
    else
      @match.predictions.create!(player: current_player, side: params[:side])
    end

    @match.reload

    render turbo_stream: [
      turbo_stream.update("match_#{@match.id}_predictions",
                           partial: "matches/predictions",
                           locals: { match: @match, player: current_player }),

    ]
  end


  private

  def whitelisted_params
    params.require(:match).permit(:play_date, :play_time, :notes, :place_id)
  end


  def load_and_authorize_record
    @match = Match.published.find params[:id]
    authorize @match
  end

end
