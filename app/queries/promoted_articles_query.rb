class PromotedArticlesQuery < ApplicationQuery
  def initialize(season)
    @season = season
  end

  def call
    @relation = @season.articles.published
                      .where("(promote_until is not null and promote_until >= ?) or (promote_until is null and published_at > ?)",
                             Date.today, Config.article_default_promotion_days.days.ago)
  end
end
