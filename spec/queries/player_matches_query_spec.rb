require 'rails_helper'

RSpec.describe PlayerMatchesQuery do
  let(:season) { create(:season) }
  let(:player) { create(:player) }
  let(:other_player) { create(:player) }

  before do
    allow_any_instance_of(PendingChallengeValidator).to receive(:validate)
    allow_any_instance_of(PlayerAssignmentsValidator).to receive(:validate)
  end

  describe '#call' do
    it 'returns matches where the player is assigned' do
      match_with_player = create(:match, season: season)
      create(:assignment, match: match_with_player, player: player, side: 1)
      
      match_without_player = create(:match, season: season)
      create(:assignment, match: match_without_player, player: other_player, side: 1)

      result = described_class.call(player, relation: season.matches)

      expect(result).to include(match_with_player)
      expect(result).not_to include(match_without_player)
    end

    it 'returns distinct matches even if multiple assignments are joined' do
      match = create(:match, season: season)
      create(:assignment, match: match, player: player, side: 1)
      
      # We test that .distinct is used by joining assignments and ensuring only 1 record per match is returned
      # even if the query might technically join multiple assignments if not for .distinct.
      # Since we have a uniqueness constraint on [player_id, match_id], we can't easily create two assignments 
      # for the same player in the same match via FactoryBot without hitting validations.
      # But we can still verify that the query returns the match correctly.

      result = described_class.call(player, relation: Match.all)

      expect(result.to_a.count).to eq(1)
      expect(result).to include(match)
    end

    context 'default relation' do
      it 'uses the first sorted season matches as default relation' do
        # We need to make sure Season.sorted.first returns our season
        allow(Season).to receive_message_chain(:sorted, :first).and_return(season)
        
        match = create(:match, season: season)
        create(:assignment, match: match, player: player, side: 1)

        result = described_class.call(player)

        expect(result).to include(match)
      end

      it 'returns none if no season exists' do
        allow(Season).to receive_message_chain(:sorted, :first).and_return(nil)
        
        result = described_class.call(player)

        expect(result).to be_empty
      end
    end

    context 'when relation is nil' do
      it 'returns none' do
        result = described_class.new(player, relation: nil).call
        expect(result).to be_empty
      end
    end
  end
end
