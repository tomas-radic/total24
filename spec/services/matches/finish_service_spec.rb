require 'rails_helper'

RSpec.describe Matches::FinishService do
  let!(:current_player) { create(:player) }
  let!(:opponent) { create(:player) }
  let!(:season) { create(:season) }
  let(:service) { Matches::FinishService.new(current_player) }

  before do
    season.players << current_player
    season.players << opponent
  end

  describe '#call' do
    let!(:match) do
      create(:match, :requested, :accepted, competitable: season,
             ranking_counted: true,
             assignments: [
               build(:assignment, player: current_player, side: 1),
               build(:assignment, player: opponent, side: 2)
             ])
    end

    context 'with valid score' do
      let(:play_date) { Date.yesterday }
      let(:place) { create(:place) }
      let(:notes) { "Great match." }
      let(:params) do
        {
          "score" => "641663",
          "play_date" => play_date.to_s,
          "place_id" => place.id,
          "notes" => notes
        }
      end

      subject { service.call(match, params) }

      it 'finishes the match and sets attributes correctly' do
        result = subject
        expect(result).to be_success
        match.reload
        expect(match).to have_attributes(
          set1_side1_score: 6,
          set1_side2_score: 4,
          set2_side1_score: 1,
          set2_side2_score: 6,
          set3_side1_score: 6,
          set3_side2_score: 3,
          winner_side: 1,
          play_date: play_date,
          notes: notes
        )
        expect(match.finished_at).to be_present
        expect(match.reviewed_at).to be_present
      end

      it 'sends notification to opponent' do
        expect(MatchFinishedNotifier).to receive(:with).with(hash_including(:record, :finished_by)).and_call_original
        expect_any_instance_of(MatchFinishedNotifier).to receive(:deliver).with(opponent)
        subject
      end
    end

    context 'with retirement' do
      let(:params) do
        {
          "score" => "6416",
          "retired_player_id" => current_player.id,
          "play_date" => Date.today.to_s
        }
      end

      subject { service.call(match, params) }

      it 'marks player as retired and sets winner correctly' do
        result = subject
        expect(result).to be_success
        match.reload
        expect(match.winner_side).to eq(2)
        expect(match.assignments.find_by(player: current_player).is_retired).to be true
      end
    end

    context 'with invalid score' do
      subject { service.call(match, { "score" => "6" }) }

      it 'does not finish the match' do
        expect { subject }.not_to change { match.reload.finished_at }
      end

      it 'returns failure result' do
        expect(subject).to be_failure
      end

      it 'populates errors' do
        result = subject
        expect(result.errors).to include("Neplatný výsledok zápasu.")
      end
    end
  end
end
