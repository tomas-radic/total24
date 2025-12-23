require 'rails_helper'

RSpec.describe Matches::RejectService do
  let!(:current_player) { create(:player) }
  let!(:opponent) { create(:player) }
  let!(:season) { create(:season) }
  let(:service) { Matches::RejectService.new }

  before do
    season.players << current_player
    season.players << opponent
  end

  describe '#call' do
    let!(:match) do
      create(:match, :requested, competitable: season, assignments: [
        build(:assignment, player: current_player, side: 1),
        build(:assignment, player: opponent, side: 2)
      ])
    end

    subject { service.call(match) }

    it 'sets the rejected_at timestamp' do
      expect { subject }.to change { match.reload.rejected_at }.from(nil)
    end

    it 'preserves open_to_play_since flags for players' do
      current_player.update(open_to_play_since: Time.current)
      opponent.update(open_to_play_since: Time.current)

      subject

      expect(current_player.reload.open_to_play_since).not_to be_nil
      expect(opponent.reload.open_to_play_since).not_to be_nil
    end

    it 'sends a notification to the challenger' do
      expect(MatchRejectedNotifier).to receive(:with).with(hash_including(:record)).and_call_original
      expect_any_instance_of(MatchRejectedNotifier).to receive(:deliver).with(current_player)
      subject
    end

    it 'returns success result' do
      expect(subject).to be_success
    end
  end
end
