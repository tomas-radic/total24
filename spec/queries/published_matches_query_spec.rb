require 'rails_helper'

RSpec.describe PublishedMatchesQuery do
  let(:season) { create(:season, ended_at: Time.current) }
  let(:other_season) { create(:season, ended_at: Time.current) }

  describe '#call' do
    before do
      allow_any_instance_of(PendingChallengeValidator).to receive(:validate)
      allow_any_instance_of(PlayerAssignmentsValidator).to receive(:validate)
    end

    it 'returns only published matches for the given season' do
      published_match = create(:match, season: season, published_at: Time.current)
      unpublished_match = create(:match, season: season, published_at: nil)
      other_season_match = create(:match, season: other_season, published_at: Time.current)

      result = described_class.call(season)

      expect(result).to include(published_match)
      expect(result).not_to include(unpublished_match)
      expect(result).not_to include(other_season_match)
    end

    context 'default ordering' do
      it 'orders by play_date asc, play_time asc, updated_at desc' do
        m1 = create(:match, :accepted, season: season, play_date: 2.days.from_now, play_time: "10:00", updated_at: 1.hour.ago)
        m2 = create(:match, :accepted, season: season, play_date: 1.day.from_now, play_time: "10:00", updated_at: 1.hour.ago)
        m3 = create(:match, :accepted, season: season, play_date: 1.day.from_now, play_time: "11:00", updated_at: 1.hour.ago)
        m4 = create(:match, :accepted, season: season, play_date: 1.day.from_now, play_time: "10:00", updated_at: 2.hours.ago)

        result = described_class.call(season)

        # Expected order:
        # m2 (1 day from now, 10:00, 1h ago)
        # m4 (1 day from now, 10:00, 2h ago)
        # m3 (1 day from now, 11:00, 1h ago)
        # m1 (2 days from now, 10:00, 1h ago)
        expect(result).to eq([m2, m4, m3, m1])
      end
    end

    context 'with unfinished_first: true' do
      it 'orders by finished_at desc nulls first, then default ordering' do
        # Unfinished matches (finished_at is nil)
        m_unfinished1 = create(:match, :accepted, season: season, finished_at: nil, play_date: 1.day.from_now, play_time: "10:00")
        m_unfinished2 = create(:match, :accepted, season: season, finished_at: nil, play_date: 2.days.from_now, play_time: "10:00")
        
        # Finished matches
        m_finished_later = create(:match, :finished, season: season, finished_at: 1.hour.ago, play_date: 1.day.ago, play_time: "10:00")
        m_finished_earlier = create(:match, :finished, season: season, finished_at: 2.hours.ago, play_date: 1.day.ago, play_time: "10:00")

        result = described_class.call(season, unfinished_first: true)

        # Expected order:
        # 1. Unfinished matches (finished_at desc nulls first -> nulls come first)
        #    Within unfinished, default order: m_unfinished1 (1 day), m_unfinished2 (2 days)
        # 2. Finished matches (finished_at desc: later first)
        #    m_finished_later (1h ago), m_finished_earlier (2h ago)
        expect(result).to eq([m_unfinished1, m_unfinished2, m_finished_later, m_finished_earlier])
      end
    end
  end
end
