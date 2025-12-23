require 'rails_helper'

RSpec.describe Matches::CancelService do
  let!(:current_player) { create(:player) }
  let!(:opponent) { create(:player) }
  let!(:season) { create(:season) }
  let(:service) { Matches::CancelService.new(current_player) }

  before do
    season.players << current_player
    season.players << opponent
  end

  describe '#call' do
    let!(:match) do
      create(:match, :requested, :accepted, competitable: season, assignments: [
        build(:assignment, player: current_player, side: 1),
        build(:assignment, player: opponent, side: 2)
      ])
    end

    subject { service.call(match) }

    it 'sets the canceled_at timestamp' do
      expect { subject }.to change { match.reload.canceled_at }.from(nil)
    end

    it 'sets the canceled_by to the current player' do
      expect { subject }.to change { match.reload.canceled_by }.to(current_player)
    end

    it 'sends a notification to match participants except the current player' do
      expect(MatchCanceledNotifier).to receive(:with).with(hash_including(:record)).and_call_original
      expect_any_instance_of(MatchCanceledNotifier).to receive(:deliver).with([opponent])
      subject
    end

    it 'returns success result' do
      expect(subject).to be_success
    end
  end
end
