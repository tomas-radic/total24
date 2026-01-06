require 'rails_helper'

RSpec.describe PromotedArticlesQuery do
  let(:season) { create(:season, ended_at: Time.current) }
  let(:other_season) { create(:season, ended_at: Time.current) }
  let(:promo_days) { Config.article_default_promotion_days }

  describe '#call' do
    it 'returns only published articles for the given season' do
      published_article = create(:article, season: season, published_at: Time.current)
      unpublished_article = create(:article, season: season, published_at: nil)
      other_season_article = create(:article, season: other_season, published_at: Time.current)

      result = described_class.call(season)

      expect(result).to include(published_article)
      expect(result).not_to include(unpublished_article)
      expect(result).not_to include(other_season_article)
    end

    it 'returns articles with promote_until in the future or today' do
      article_today = create(:article, season: season, promote_until: Date.today)
      article_future = create(:article, season: season, promote_until: Date.tomorrow)
      article_past = create(:article, season: season, promote_until: Date.yesterday)

      result = described_class.call(season)

      expect(result).to include(article_today, article_future)
      expect(result).not_to include(article_past)
    end

    it 'returns newly published articles when promote_until is null' do
      # Exactly at threshold
      article_threshold = create(:article, season: season, promote_until: nil, 
                                 published_at: promo_days.days.ago + 1.minute)
      # Well within threshold
      article_new = create(:article, season: season, promote_until: nil, 
                           published_at: 1.day.ago)
      # Outside threshold
      article_old = create(:article, season: season, promote_until: nil, 
                           published_at: (promo_days + 1).days.ago)

      result = described_class.call(season)

      expect(result).to include(article_threshold, article_new)
      expect(result).not_to include(article_old)
    end

    it 'prioritizes promote_until over newly published status if promote_until is set' do
      # Article is old, but has promote_until in the future
      article = create(:article, season: season, 
                       promote_until: Date.tomorrow, 
                       published_at: 10.days.ago)
      
      result = described_class.call(season)
      expect(result).to include(article)
    end
  end
end
