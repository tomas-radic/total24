require 'rails_helper'

RSpec.describe UpcomingTournamentsQuery do
  let(:season) { create(:season, ended_at: Time.current) }
  let(:other_season) { create(:season, ended_at: Time.current) }
  
  let(:before_days) { Config.before_tournament_days_notice }
  let(:after_days) { Config.after_tournament_days_notice }

  describe '#call' do
    it 'returns only published tournaments for the given season' do
      published_t = create(:tournament, season: season, published_at: Time.current)
      unpublished_t = create(:tournament, season: season, published_at: nil)
      other_season_t = create(:tournament, season: other_season, published_at: Time.current)

      result = described_class.call(season)

      expect(result).to include(published_t)
      expect(result).not_to include(unpublished_t)
      expect(result).not_to include(other_season_t)
    end

    it 'returns tournaments that start within configured number of days' do
      # Starts exactly at the threshold
      t_threshold = create(:tournament, season: season, 
                           begin_date: Date.current + before_days.days,
                           end_date: Date.current + before_days.days)
      # Starts just within the threshold
      t_within = create(:tournament, season: season, 
                        begin_date: Date.current + (before_days - 1).days,
                        end_date: Date.current + (before_days - 1).days)
      # Starts outside the threshold
      t_outside = create(:tournament, season: season, 
                         begin_date: Date.current + (before_days + 1).days,
                         end_date: Date.current + (before_days + 1).days)

      result = described_class.call(season)

      expect(result).to include(t_threshold, t_within)
      expect(result).not_to include(t_outside)
    end

    it 'returns tournaments that ended within configured number of days ago' do
      # Ended exactly at the threshold (after_days ago)
      # Tournament is upcoming if end_date >= Date.current - after_days.days
      t_ended_threshold = create(:tournament, season: season, 
                                 begin_date: Date.current - (after_days + 5).days, 
                                 end_date: Date.current - after_days.days)
      
      # Ended long ago
      t_ended_long_ago = create(:tournament, season: season, 
                                begin_date: Date.current - (after_days + 10).days, 
                                end_date: Date.current - (after_days + 1).days)

      result = described_class.call(season)

      expect(result).to include(t_ended_threshold)
      expect(result).not_to include(t_ended_long_ago)
    end

    it 'returns tournaments that are currently happening' do
      t_ongoing = create(:tournament, season: season, 
                         begin_date: Date.current - 1.day, 
                         end_date: Date.current + 1.day)
      
      result = described_class.call(season)
      expect(result).to include(t_ongoing)
    end
    
    it 'orders by begin_date asc and updated_at desc' do
      t1 = create(:tournament, season: season, 
                  begin_date: Date.current + 2.days, 
                  end_date: Date.current + 2.days,
                  updated_at: 1.hour.ago)
      t2 = create(:tournament, season: season, 
                  begin_date: Date.current + 1.day, 
                  end_date: Date.current + 1.day,
                  updated_at: 1.hour.ago)
      t3 = create(:tournament, season: season, 
                  begin_date: Date.current + 1.day, 
                  end_date: Date.current + 1.day,
                  updated_at: 2.hours.ago)

      result = described_class.call(season)

      # Expected order: t2 (1 day, 1h ago), t3 (1 day, 2h ago), t1 (2 days, 1h ago)
      expect(result.to_a).to eq([t2, t3, t1])
    end
  end
end
