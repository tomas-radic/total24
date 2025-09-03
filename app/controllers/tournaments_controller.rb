class TournamentsController < ApplicationController

  def index
    if selected_season.present?
      @tournaments = selected_season.tournaments.published.sorted
    end
  end


  def show
    @tournament = selected_season.tournaments.published.find(params[:id])
    @planned_matches = @tournament.matches
                                  .published.pending.order(play_date: :asc, play_time: :asc, updated_at: :desc)
                                  .includes(:reactions, :comments, :reacted_players, :predictions, :place, assignments: :player)
    @finished_matches = @tournament.matches
                                   .published.finished.sorted
                                   .includes(:reactions, :comments, :reacted_players, assignments: :player)

    if current_player.present?
      now = Time.current
      @tournament.notifications.where(recipient_id: current_player.id).each do |n|
        n.update(seen_at: now, read_at: now)
      end
    end
  end

end
