require 'rails_helper'

RSpec.describe Matches::AcceptService do
  let!(:current_player) { create(:player) }
  let!(:opponent) { create(:player) }
  let!(:season) { create(:season) }
  let(:service) { Matches::AcceptService.new(current_player) }

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

    it 'sets the accepted_at timestamp' do
      subject
      expect(match.reload.accepted_at).to be_present
    end

    it 'clears open_to_play_since for all players in the match' do
      current_player.update(open_to_play_since: Time.current)
      opponent.update(open_to_play_since: Time.current)

      subject

      expect(current_player.reload.open_to_play_since).to be_nil
      expect(opponent.reload.open_to_play_since).to be_nil
    end

    it 'sends a notification to the challenger' do
      expect(MatchAcceptedNotifier).to receive(:with).with(hash_including(:record)).and_call_original
      expect_any_instance_of(MatchAcceptedNotifier).to receive(:deliver).with(current_player)
      subject
    end

    it 'returns success result' do
      expect(subject).to be_success
    end

    context 'when update fails' do
      before do
        allow_any_instance_of(Match).to receive(:update).and_return(false)
        allow_any_instance_of(ActiveModel::Errors).to receive(:full_messages).and_return(["Error message"])
      end

      it 'returns failure result' do
        expect(subject).to be_failure
      end

      it 'populates errors' do
        result = subject
        expect(result.errors).to include("Error message")
      end
    end
  end
end
