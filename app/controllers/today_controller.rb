class TodayController < ApplicationController

  def index
    if selected_season.present?
      season_matches = selected_season.matches.published.ranking_counted
                                      .order(play_date: :asc, play_time: :asc, updated_at: :desc)
                                      .includes(:reactions, :comments, :reacted_players, :place,
                                                :predictions, assignments: :player)

      @requested_matches = season_matches.select do |match|
        match.requested_at.present? && match.accepted_at.nil? && match.rejected_at.nil? &&
          match.finished_at.nil? && match.canceled_at.nil?
      end.sort_by { |match| -match.requested_at.to_i }

      @rejected_matches = season_matches.select do |match|
        match.recently_rejected?
      end.sort_by { |match| -match.rejected_at.to_i }

      @recent_matches = season_matches.select do |match|
        match.reviewed_at.present? && match.recently_finished?
      end.sort_by { |match| -match.finished_at.to_i }

      @planned_matches = season_matches.select do |match|
        match.accepted_at.present? && match.finished_at.nil? && match.canceled_at.nil? &&
          (match.play_date.blank? || match.play_date >= Time.now.in_time_zone.to_date)
      end








      @canceled_matches = season_matches.select do |match|
        match.recently_canceled?
      end.sort_by { |match| -match.canceled_at.to_i }

      begins_in_days = Date.today + 12.days
      ended_before_days = Date.today - 2.days
      @upcoming_tournaments = selected_season.tournaments.published
                                             .where("(begin_date < ? or end_date < ?) and (end_date >= ?)",
                                                    begins_in_days, begins_in_days, ended_before_days)
      @actual_articles = selected_season.articles.published
                                        .where("(promote_until is not null and promote_until >= ?) or (promote_until is null and created_at > ?)",
                                               Date.today, 4.days.ago)

      @top_rankings = Rankings.calculate(selected_season, single_matches: true)
                              .slice(0, selected_season.play_off_size + 2)

      @players_open_to_play = selected_season.players
                                             .where.not(open_to_play_since: nil)
                                             .order(open_to_play_since: :desc)
    end
  end

end
