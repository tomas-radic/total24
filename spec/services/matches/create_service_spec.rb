require 'rails_helper'

RSpec.describe Matches::CreateService do
  let!(:current_player) { create(:player) }
  let!(:opponent) { create(:player) }
  let!(:season) { create(:season) }
  let(:service) { Matches::CreateService.new(current_player) }

  before do
    season.players << current_player
    season.players << opponent
  end

  describe '#call' do
    subject { service.call(season, opponent) }

    context 'with valid parameters' do
      it 'creates and saves a new match' do
        expect { subject }.to change(Match, :count).by(1)
      end

      it 'sets the current player as challenger (side 1)' do
        result = subject
        challenger_assignment = result.value.assignments.find_by(side: 1)
        expect(challenger_assignment.player).to eq(current_player)
      end

      it 'sets the opponent as challenged (side 2)' do
        result = subject
        challenged_assignment = result.value.assignments.find_by(side: 2)
        expect(challenged_assignment.player).to eq(opponent)
      end

      it 'sets requested_at and published_at' do
        result = subject
        expect(result.value.requested_at).to be_present
        expect(result.value.published_at).to be_present
      end

      it 'sets ranking_counted to true' do
        result = subject
        expect(result.value.ranking_counted).to be true
      end

      it 'clears cant_play_since for the current player' do
        current_player.update(cant_play_since: Time.current)
        subject
        expect(current_player.reload.cant_play_since).to be_nil
      end

      it 'sends a notification to the opponent' do
        expect(NewMatchNotifier).to receive(:with).with(hash_including(:record)).and_call_original
        expect_any_instance_of(NewMatchNotifier).to receive(:deliver).with(opponent)
        subject
      end

      it 'returns success result' do
        expect(subject).to be_success
      end

      it 'exposes the created match' do
        result = subject
        expect(result.value).to be_a(Match)
        expect(result.value).to be_persisted
      end
    end

    context 'with invalid match data' do
      it 'does not save the match' do
        # Passing nil for season will make it invalid
        expect { service.call(Season.new, opponent) }.not_to change(Match, :count)
      end

      it 'returns failure result' do
        expect(service.call(Season.new, opponent)).to be_failure
      end
    end
  end
end
