require 'rails_helper'

RSpec.describe Matches::SwitchPredictionService do
  let!(:current_player) { create(:player) }
  let!(:season) { create(:season) }
  let(:service) { Matches::SwitchPredictionService.new(current_player) }

  describe '#call' do
    let!(:match) { create(:match, season: season) }

    context 'when no prediction exists' do
      subject { service.call(match, 1) }

      it 'creates a new prediction' do
        expect { subject }.to change(Prediction, :count).by(1)
      end

      it 'creates prediction for current player with correct side' do
        subject
        expect(match.predictions.find_by(player: current_player, side: 1)).to be_present
      end
    end

    context 'when a prediction already exists' do
      let!(:existing_prediction) { create(:prediction, match: match, player: current_player, side: 1) }

      context 'and switching to the same side' do
        subject { service.call(match, 1) }

        it 'removes the prediction' do
          expect { subject }.to change(Prediction, :count).by(-1)
        end
      end

      context 'and switching to a different side' do
        subject { service.call(match, 2) }

        it 'updates the prediction to new side' do
          expect { subject }.to change { existing_prediction.reload.side }.from(1).to(2)
        end
      end
    end
  end
end
