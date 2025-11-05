require 'rails_helper'

RSpec.describe MatchService do
  let!(:current_player) { create(:player) }
  let!(:opponent) { create(:player) }
  let!(:season) { create(:season, enrollments: [
    build(:enrollment, player: current_player),
    build(:enrollment, player: opponent)
  ]) }
  let(:service) { MatchService.new(current_player) }

  describe '#initialize' do
    it 'requires current_player' do
      expect { MatchService.new(nil) }.to raise_error(ArgumentError, "current_player is required")
    end

    it 'accepts current_player' do
      expect { MatchService.new(current_player) }.not_to raise_error
    end
  end

  describe '#create' do
    context 'with valid parameters' do
      it 'creates and saves a new match' do
        expect {
          service.create(season, opponent)
        }.to change(Match, :count).by(1)
      end

      it 'sets the current player as challenger (side 1)' do
        service.create(season, opponent)
        challenger_assignment = service.match.assignments.find_by(side: 1)
        expect(challenger_assignment.player).to eq(current_player)
      end

      it 'sets the opponent as challenged (side 2)' do
        service.create(season, opponent)
        challenged_assignment = service.match.assignments.find_by(side: 2)
        expect(challenged_assignment.player).to eq(opponent)
      end

      it 'sets requested_at and published_at' do
        service.create(season, opponent)
        expect(service.match.requested_at).to be_present
        expect(service.match.published_at).to be_present
      end

      it 'sets ranking_counted to true' do
        service.create(season, opponent)
        expect(service.match.ranking_counted).to be true
      end

      it 'clears cant_play_since for the current player' do
        current_player.update(cant_play_since: Time.current)
        service.create(season, opponent)
        expect(current_player.reload.cant_play_since).to be_nil
      end

      it 'sends a notification to the opponent' do
        expect(NewMatchNotifier).to receive(:with).with(hash_including(:record)).and_call_original
        expect_any_instance_of(NewMatchNotifier).to receive(:deliver).with(opponent)
        service.create(season, opponent)
      end

      it 'returns true' do
        expect(service.create(season, opponent)).to be true
      end

      it 'exposes the created match' do
        service.create(season, opponent)
        expect(service.match).to be_a(Match)
        expect(service.match).to be_persisted
      end
    end

    context 'with invalid match data' do
      before do
        allow_any_instance_of(Match).to receive(:save).and_return(false)
      end

      it 'does not save the match' do
        expect {
          service.create(season, opponent)
        }.not_to change(Match, :count)
      end

      it 'returns false' do
        expect(service.create(season, opponent)).to be false
      end

      it 'exposes the unsaved match' do
        service.create(season, opponent)
        expect(service.match).to be_a(Match)
        expect(service.match).not_to be_persisted
      end
    end
  end

  describe '#accept' do
    let!(:match) do
      create(:match, :requested, competitable: season, assignments: [
        build(:assignment, player: current_player, side: 1),
        build(:assignment, player: opponent, side: 2)
      ])
    end

    it 'sets the accepted_at timestamp' do
      service.accept(match)
      expect(match.reload.accepted_at).to be_present
    end

    it 'clears open_to_play_since for all players in the match' do
      current_player.update(open_to_play_since: Time.current)
      opponent.update(open_to_play_since: Time.current)

      service.accept(match)

      expect(current_player.reload.open_to_play_since).to be_nil
      expect(opponent.reload.open_to_play_since).to be_nil
    end

    it 'sends a notification to the challenger' do
      expect(MatchAcceptedNotifier).to receive(:with).with(hash_including(:record)).and_call_original
      expect_any_instance_of(MatchAcceptedNotifier).to receive(:deliver).with(current_player)
      service.accept(match)
    end

    it 'returns true' do
      expect(service.accept(match)).to be true
    end

    context 'when update fails' do
      before do
        allow(match).to receive(:update).and_return(false)
        allow(match).to receive_message_chain(:errors, :full_messages).and_return(["Error message"])
      end

      it 'returns false' do
        expect(service.accept(match)).to be false
      end

      it 'populates errors' do
        service.accept(match)
        expect(service.errors).to include("Error message")
      end
    end
  end

  describe '#reject' do
    let!(:match) do
      create(:match, :requested, competitable: season, assignments: [
        build(:assignment, player: current_player, side: 1),
        build(:assignment, player: opponent, side: 2)
      ])
    end

    it 'sets the rejected_at timestamp' do
      expect {
        service.reject(match)
      }.to change { match.reload.rejected_at }.from(nil)
    end

    it 'sends a notification to the challenger' do
      expect(MatchRejectedNotifier).to receive(:with).with(hash_including(:record)).and_call_original
      expect_any_instance_of(MatchRejectedNotifier).to receive(:deliver).with(current_player)
      service.reject(match)
    end

    it 'returns true' do
      expect(service.reject(match)).to be true
    end
  end

  describe '#cancel' do
    let!(:match) do
      create(:match, :requested, :accepted, competitable: season, assignments: [
        build(:assignment, player: current_player, side: 1),
        build(:assignment, player: opponent, side: 2)
      ])
    end

    before do
      allow(match).to receive(:notification_recipients_for).and_return([opponent])
    end

    it 'sets the canceled_at timestamp' do
      expect {
        service.cancel(match)
      }.to change { match.reload.canceled_at }.from(nil)
    end

    it 'sets the canceled_by to the current player' do
      expect {
        service.cancel(match)
      }.to change { match.reload.canceled_by }.to(current_player)
    end

    it 'sends a notification to match participants except the current player' do
      expect(MatchCanceledNotifier).to receive(:with).with(hash_including(:record)).and_call_original
      expect_any_instance_of(MatchCanceledNotifier).to receive(:deliver).with([opponent])
      service.cancel(match)
    end

    it 'returns true' do
      expect(service.cancel(match)).to be true
    end
  end

  describe '#finish' do
    let!(:match) do
      create(:match, :requested, :accepted, competitable: season,
             ranking_counted: true,
             assignments: [
               build(:assignment, player: current_player, side: 1),
               build(:assignment, player: opponent, side: 2)
             ])
    end

    context 'with valid score' do
      it 'finishes the match' do
        expect {
          service.finish(match, { "score" => "64" })
        }.to change { match.reload.finished_at }.from(nil)
      end

      it 'sends notification to opponent' do
        expect(MatchFinishedNotifier).to receive(:with).with(hash_including(:record, :finished_by)).and_call_original
        expect_any_instance_of(MatchFinishedNotifier).to receive(:deliver).with(opponent)
        service.finish(match, { "score" => "64" })
      end

      it 'returns true' do
        expect(service.finish(match, { "score" => "64" })).to be true
      end
    end

    context 'with invalid score' do
      it 'does not finish the match' do
        expect {
          service.finish(match, { "score" => "6" })
        }.not_to change { match.reload.finished_at }
      end

      it 'returns false' do
        expect(service.finish(match, { "score" => "6" })).to be false
      end

      it 'populates errors' do
        service.finish(match, { "score" => "6" })
        expect(service.errors).not_to be_empty
      end
    end
  end

  describe '#toggle_reaction' do
    let!(:match) { create(:match, competitable: season) }

    context 'when no reaction exists' do
      it 'creates a new reaction' do
        expect {
          service.toggle_reaction(match)
        }.to change(Reaction, :count).by(1)
      end

      it 'creates reaction for current player' do
        service.toggle_reaction(match)
        expect(match.reactions.find_by(player: current_player)).to be_present
      end
    end

    context 'when a reaction already exists' do
      let!(:existing_reaction) { create(:reaction, reactionable: match, player: current_player) }

      it 'removes the existing reaction' do
        expect {
          service.toggle_reaction(match)
        }.to change(Reaction, :count).by(-1)
      end
    end
  end

  describe '#switch_prediction' do
    let!(:match) { create(:match, competitable: season) }

    context 'when no prediction exists' do
      it 'creates a new prediction' do
        expect {
          service.switch_prediction(match, 1)
        }.to change(Prediction, :count).by(1)
      end

      it 'creates prediction for current player' do
        service.switch_prediction(match, 1)
        expect(match.predictions.find_by(player: current_player, side: 1)).to be_present
      end
    end

    context 'when a prediction already exists' do
      let!(:existing_prediction) { create(:prediction, match: match, player: current_player, side: 1) }

      context 'and switching to the same side' do
        it 'removes the prediction' do
          expect {
            service.switch_prediction(match, 1)
          }.to change(Prediction, :count).by(-1)
        end
      end

      context 'and switching to a different side' do
        it 'updates the prediction' do
          expect {
            service.switch_prediction(match, 2)
          }.to change { existing_prediction.reload.side }.from(1).to(2)
        end
      end
    end
  end

  describe '#update' do
    let!(:match) do
      create(:match, :requested, :accepted, competitable: season,
             assignments: [
               build(:assignment, player: current_player, side: 1),
               build(:assignment, player: opponent, side: 2)
             ])
    end

    let(:params) { { notes: "Updated notes" } }

    it 'updates the match' do
      expect {
        service.update(match, params)
      }.to change { match.reload.notes }.to("Updated notes")
    end

    it 'returns true' do
      expect(service.update(match, params)).to be true
    end

    context 'with another player who commented' do
      let!(:other_player) { create(:player) }
      let!(:comment) { create(:comment, commentable: match, player: other_player) }

      it 'sends notification to interested players except current player' do
        expect(MatchUpdatedNotifier).to receive(:with).with(hash_including(:record)).and_call_original
        service.update(match, params)
      end
    end
  end
end
