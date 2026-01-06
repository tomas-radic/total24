class UpcomingTournamentsQuery < ApplicationQuery
  def initialize(season)
    @season = season
  end

  def call
    @relation = @season.tournaments.published.order(begin_date: :asc, updated_at: :desc)
    filter_upcoming
    @relation
  end

  private

  def filter_upcoming
    @relation = @relation.where("(begin_date <= ?) and ((end_date >= ?) or (begin_date >= ?))",
                                days_before_tournament, days_after_tournament, days_after_tournament)
  end

  def days_before_tournament
    Date.current + Config.before_tournament_days_notice.days
  end

  def days_after_tournament
    Date.current - Config.after_tournament_days_notice.days
  end
end
