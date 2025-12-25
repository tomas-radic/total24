class Player::MatchesController < Player::BaseController
  before_action :load_and_authorize_record, except: [:create, :toggle_reaction, :switch_prediction]
  after_action :verify_authorized, except: [:create, :toggle_reaction]

  def create
    @requested_player = Player.where(anonymized_at: nil).find(params[:player_id])

    unless MatchPolicy.new(current_player, nil).create?(selected_season, @requested_player)
      raise Pundit::NotAuthorizedError, "nie je možné vyzvať hráča #{@requested_player.name}"
    end

    service = Matches::CreateService.new(current_player)
    result = service.call(selected_season, @requested_player)
    if result.success?
      redirect_with_message match_path(result.value), 'Výzva bola vytvorená.'
    else
      redirect_with_message player_path(@requested_player), 'Výzvu sa nepodarilo vytvoriť.', :alert
    end
  end

  def edit
  end

  def update
    service = Matches::UpdateService.new(current_player)
    result = service.call(@match, whitelisted_params)
    if result.success?
      broadcast_match_update(@match)
      recipients = @match.notification_recipients_for(MatchUpdatedNotifier)
      recipients = recipients.reject { |recipient| recipient.id == @current_player.id }
      MatchUpdatedNotifier.with(record: @match).deliver(recipients)

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
    service = Matches::AcceptService.new(current_player)
    result = service.call(@match)
    if result.success?
      broadcast_players_open_to_play
      broadcast_match_update(@match)
      challenger = @match.assignments.find { |a| a.side == 1 }.player
      MatchAcceptedNotifier.with(record: @match).deliver(challenger)

      redirect_to match_path(@match)
    else
      redirect_to match_path(@match), alert: result.errors.join(", ")
    end
  end

  def reject
    service = Matches::RejectService.new
    result = service.call(@match)
    if result.success?
      broadcast_match_update(@match)
      challenger = @match.assignments.find { |a| a.side == 1 }.player
      MatchRejectedNotifier.with(record: @match).deliver(challenger)

      redirect_to match_path(@match)
    else
      redirect_to match_path(@match), alert: result.errors.join(", ")
    end
  end

  def finish_init
  end

  def finish
    service = Matches::FinishService.new(current_player)
    params_to_finish = params.slice("score", "retired_player_id", "play_date", "place_id", "notes")

    result = service.call(@match, params_to_finish)
    if result.success?
      broadcast_match_update(@match)
      opponent = @match.assignments.find { |a| a.player_id != @current_player.id }.player
      MatchFinishedNotifier.with(record: @match, finished_by: @current_player).deliver(opponent)

      redirect_with_message match_path(@match), 'Zápas bol zapísaný, rebríček sa aktualizuje časom.'
    else
      render_with_message :finish_init, 'Zápas sa nepodarilo zapísať.'
    end
  end

  def cancel
    service = Matches::CancelService.new(current_player)
    result = service.call(@match)
    if result.success?
      broadcast_match_update(@match)
      recipients = @match.notification_recipients_for(MatchCanceledNotifier)
      recipients = recipients.reject { |recipient| recipient.id == @current_player.id }
      MatchCanceledNotifier.with(record: @match).deliver(recipients)

      redirect_with_message match_path(@match), 'Zápas bol zrušený.'
    else
      redirect_with_message match_path(@match), 'Zápas sa nepodarilo zrušiť.', :alert
    end
  end

  def toggle_reaction
    @match = Match.published.find(params[:id])
    service = Matches::ToggleReactionService.new(current_player)
    service.call(@match)

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

    service = Matches::SwitchPredictionService.new(current_player)
    service.call(@match, params[:side])

    render turbo_stream: [
      turbo_stream.update("match_#{@match.id}_predictions",
                          partial: "matches/predictions",
                          locals: { match: @match, player: current_player })
    ]
  end

  def mark_notifications_read
    service = Matches::MarkNotificationsReadService.new(current_player)
    service.call(@match)

    respond_to do |format|
      format.turbo_stream do
        refresh_notifications_for(current_player)
      end

      format.html { redirect_back(fallback_location: root_path) }
      format.any { head :ok }
    end
  end

  private

  def whitelisted_params
    params.require(:match).permit(:play_date, :play_time, :notes, :place_id)
  end

  def load_and_authorize_record
    @match = Match.published.find(params[:id])
    authorize @match
  end
end
