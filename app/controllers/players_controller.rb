class PlayersController < ApplicationController

  # Temporary action, turn off later.
  def index
    @players = Player.active.order(created_at: :desc)
  end


  def show
    @player = Player.find params[:id]

    if selected_season.present?
      @pending_matches = @player.matches.in_season(selected_season).published.pending
      @completed_matches = @player.matches.in_season(selected_season).published.reviewed.sorted.includes(assignments: :player)
      @won_matches_count = @completed_matches.count do |match|
        player_assignment = match.assignments.find { |a| a.player_id == @player.id }
        match.winner_side == player_assignment.side
      end

      if current_player
        @cp_pending_matches = current_player.matches.in_season(selected_season).published.pending
        @cp_completed_matches = current_player.matches.in_season(selected_season).published.reviewed.sorted.includes(assignments: :player)
      end
    end
  end

end
