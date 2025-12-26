class TodayController < ApplicationController

  def index
    if selected_season.present?
      @privacy = current_player.blank?
      load_matches
      load_tournaments
      load_articles
      load_players
    end
  end

  private

  def load_matches
    season_matches = selected_season.matches.published.ranking_counted
                                    .order(play_date: :asc, play_time: :asc, updated_at: :desc)
                                    .includes(:reactions, :comments, :players,
                                              :predictions, assignments: :player)

    @requested_matches = season_matches.select do |match|
      match.requested? && !match.accepted? && !match.rejected? && !match.finished? && !match.canceled?
    end.sort_by { |match| -match.requested_at.to_i }

    @rejected_matches = season_matches.select do |match|
      match.recently_rejected?
    end.sort_by { |match| -match.rejected_at.to_i }

    @recent_matches = season_matches.select do |match|
      match.reviewed? && match.recently_finished?
    end.sort_by { |match| -match.finished_at.to_i }

    @planned_matches = season_matches.select do |match|
      match.accepted? && !match.finished? && !match.canceled? &&
        (match.play_date.blank? || match.play_date >= Time.current.to_date)
    end

    @canceled_matches = season_matches.select do |match|
      match.recently_canceled?
    end.sort_by { |match| -match.canceled_at.to_i }
  end

  def load_tournaments
    begins_in_days = Date.today + 12.days
    ended_before_days = Date.today - 2.days
    @upcoming_tournaments = selected_season.tournaments.published
                                           .where("(begin_date < ? or end_date < ?) and (end_date >= ?)",
                                                  begins_in_days, begins_in_days, ended_before_days)
                                           .order(begin_date: :asc, updated_at: :desc)
  end

  def load_articles
    @actual_articles = selected_season.articles.published
                                      .where("(promote_until is not null and promote_until >= ?) or (promote_until is null and created_at > ?)",
                                             Date.today, 4.days.ago)
  end

  def load_players
    @players_open_to_play = selected_season.players.open_to_play
  end

end
