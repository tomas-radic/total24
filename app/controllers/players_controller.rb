class PlayersController < ApplicationController

  # Temporary action, turn off later.
  def index
    @players = Player.where(anonymized_at: nil, access_denied_since: nil).order(created_at: :desc)
  end


  def show
    @player = Player.find params[:id]

    if selected_season.present?
      @all_matches = @player.season_matches(selected_season).includes(assignments: :player)
      @won_matches_count = @all_matches.count do |match|
        player_assignment = match.assignments.find { |a| a.player_id == @player.id }
        match.winner_side == player_assignment.side
      end

      if current_player
        @common_matches = Match.singles_with_players(current_player, @player, competitable: selected_season)
      end
    end
  end

end
