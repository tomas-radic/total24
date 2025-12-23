require 'rails_helper'

RSpec.describe Matches::ToggleReactionService do
  let!(:current_player) { create(:player) }
  let!(:season) { create(:season) }
  let(:service) { Matches::ToggleReactionService.new(current_player) }

  describe '#call' do
    let!(:match) { create(:match, competitable: season) }

    subject { service.call(match) }

    context 'when no reaction exists' do
      it 'creates a new reaction' do
        expect { subject }.to change(Reaction, :count).by(1)
      end

      it 'creates reaction for current player' do
        subject
        expect(match.reactions.find_by(player: current_player)).to be_present
      end
    end

    context 'when a reaction already exists' do
      let!(:existing_reaction) { create(:reaction, reactionable: match, player: current_player) }

      it 'removes the existing reaction' do
        expect { subject }.to change(Reaction, :count).by(-1)
      end
    end
  end
end
