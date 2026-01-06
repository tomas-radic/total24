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
    season_matches = PublishedMatchesQuery.call(selected_season).includes(:reactions, :comments, :players,
                                                                         :predictions, assignments: :player)

    @requested_matches = season_matches.select do |match|
      match.requested?
    end.sort_by { |match| -match.created_at.to_i }

    @rejected_matches = season_matches.select do |match|
      match.recently_rejected?
    end.sort_by { |match| -match.rejected_at.to_i }

    @recent_matches = season_matches.select do |match|
      match.recently_finished?
    end.sort_by { |match| -match.finished_at.to_i }

    @planned_matches = season_matches.select do |match|
      match.accepted? && (match.play_date.blank? || match.play_date >= Time.current.to_date)
    end

    @canceled_matches = season_matches.select do |match|
      match.recently_canceled?
    end.sort_by { |match| -match.canceled_at.to_i }
  end

  def load_tournaments
    @upcoming_tournaments = UpcomingTournamentsQuery.call(selected_season)
  end

  def load_articles
    @promoted_articles = PromotedArticlesQuery.call(selected_season)
  end

  def load_players
    @players_open_to_play = selected_season.players.open_to_play
  end

end
