class MatchesController < ApplicationController

  def index
    if selected_season.present?
      page = params[:page] || 1

      @matches = PublishedMatchesQuery.call(selected_season, unfinished_first: true)
                                      .where(rejected_at: nil, canceled_at: nil)
                                      .includes(:place, :reactions, :comments, :reacted_players, :predictions,
                                                :players, assignments: :player)
      @reviewed_count = @matches.count { |m| m.reviewed? }
      @planned_count = @matches.count { |m| !m.reviewed? }
      @matches = @matches.page(page).per(100)

      if player_signed_in?
        @pending_matches = PlayerMatchesQuery.call(current_player, relation: @matches).pending
                                             .includes(:reactions, :comments, :predictions, :players,
                                                       assignments: :player)
      end
    end
  end


  def show
    @match = Match.published.find params[:id]

    if current_player.present?
      @comment = @match.comments.new
      @player_prediction = @match.predictions.find_by(player: current_player)
    end
  end
end
