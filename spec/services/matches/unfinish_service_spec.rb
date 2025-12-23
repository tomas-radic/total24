require 'rails_helper'

RSpec.describe Matches::UnfinishService do
  let!(:current_player) { create(:player) }
  let!(:opponent) { create(:player) }
  let!(:season) { create(:season) }

  before do
    create(:enrollment, season: season, player: current_player)
    create(:enrollment, season: season, player: opponent)
  end

  let!(:match) do
    create(:match, :reviewed, competitable: season,
           assignments: [
             build(:assignment, player: current_player, side: 1, is_retired: false),
             build(:assignment, player: opponent, side: 2, is_retired: true)
           ])
  end

  let(:service) { Matches::UnfinishService.new(current_player) }

  describe '#call' do
    subject { service.call(match) }

    it 'clears all finish-related attributes' do
      subject
      match.reload

      expect(match.finished_at).to be_nil
      expect(match.reviewed_at).to be_nil
      expect(match.winner_side).to be_nil
      expect(match.set1_side1_score).to be_nil
      expect(match.set1_side2_score).to be_nil
      expect(match.set2_side1_score).to be_nil
      expect(match.set2_side2_score).to be_nil
      expect(match.set3_side1_score).to be_nil
      expect(match.set3_side2_score).to be_nil
    end

    it 'resets retirement status for all assignments' do
      subject
      match.reload

      expect(match.assignments.pluck(:is_retired)).to all(be false)
    end

    it 'returns success result' do
      expect(subject).to be_success
    end

    it 'exposes the match' do
      expect(subject.value).to eq(match)
    end
  end
end
