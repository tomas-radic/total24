require 'rails_helper'

RSpec.describe Matches::UpdateService do
  let!(:current_player) { create(:player) }
  let!(:opponent) { create(:player) }
  let!(:season) { create(:season) }
  let(:service) { Matches::UpdateService.new(current_player) }

  before do
    season.players << current_player
    season.players << opponent
  end

  describe '#call' do
    let!(:match) do
      create(:match, :requested, :accepted, competitable: season,
             assignments: [
               build(:assignment, player: current_player, side: 1),
               build(:assignment, player: opponent, side: 2)
             ])
    end

    context 'with valid params' do
      let(:place) { create(:place) }
      let(:play_date) { Date.tomorrow }
      let(:play_time) { Match.play_times.keys.sample }
      let(:params) do
        {
          play_date: play_date,
          play_time: play_time,
          notes: "Updated notes",
          place_id: place.id
        }
      end

      subject { service.call(match, params) }

      it 'updates the match attributes' do
        subject
        match.reload

        expect(match.play_date).to eq(play_date)
        expect(match.play_time).to eq(play_time)
        expect(match.notes).to eq("Updated notes")
        expect(match.place_id).to eq(place.id)
      end

      it 'returns success result' do
        expect(subject).to be_success
      end
    end
  end
end
