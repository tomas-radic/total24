class PublishedMatchesQuery < ApplicationQuery
  def initialize(season, unfinished_first: false)
    @season = season
    @unfinished_first = unfinished_first
  end

  def call
    @relation = @season.matches.published
    order_by_finish_time if @unfinished_first
    apply_default_ordering
    @relation
  end

  private

  def order_by_finish_time
    @relation = @relation.order("finished_at desc nulls first")
  end

  def apply_default_ordering
    @relation = @relation.order("play_date asc nulls last, play_time asc nulls last, updated_at desc")
  end
end