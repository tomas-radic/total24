require 'rails_helper'

RSpec.describe MatchService do
  let!(:current_player) { create(:player) }
  let!(:opponent) { create(:player) }
  let!(:season) { create(:season) }
  let(:service) { MatchService.new(current_player) }

  before do
    season.players << current_player
    season.players << opponent
  end

  describe '#initialize' do
    it 'requires current_player' do
      expect { MatchService.new(nil) }.to raise_error(ArgumentError, "current_player is required")
    end

    it 'accepts current_player' do
      expect { MatchService.new(current_player) }.not_to raise_error
    end
  end

  describe '#create' do
    subject { service.create(season, opponent) }

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
        expect { service.create(Season.new, opponent) }.not_to change(Match, :count)
      end

      it 'returns failure result' do
        expect(service.create(Season.new, opponent)).to be_failure
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

      subject { service.update(match, params) }

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

      context 'with another player who commented' do
        let!(:other_player) { create(:player) }
        let!(:comment) { create(:comment, commentable: match, player: other_player) }

        subject { service.update(match, { notes: "Updated" }) }

        it 'sends notification to interested players except current player' do
          expect(MatchUpdatedNotifier).to receive(:with).with(hash_including(:record)).and_call_original
          expect_any_instance_of(MatchUpdatedNotifier).to receive(:deliver)
          subject
        end

        context 'when player already has unseen notification for the match' do
          before do
            Noticed::Notification.create!(
              recipient: other_player,
              seen_at: nil,
              read_at: nil,
              type: "MatchUpdatedNotifier::Notification",
              event: Noticed::Event.create!(record: match, type: "MatchUpdatedNotifier")
            )
          end

          it 'does not send duplicate notification' do
            notifications_count = other_player.notifications.count
            subject
            expect(other_player.notifications.count).to eq(notifications_count)
          end
        end

        context 'when player has seen notification for the match' do
          before do
            Noticed::Notification.create!(
              recipient: other_player,
              seen_at: 1.hour.ago,
              read_at: nil,
              type: "MatchUpdatedNotifier::Notification",
              event: Noticed::Event.create!(record: match, type: "MatchUpdatedNotifier")
            )
          end

          it 'sends new notification' do
            expect { subject }.to change { other_player.notifications.count }.by(1)
          end
        end
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

    subject { service.accept(match) }

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

  describe '#reject' do
    let!(:match) do
      create(:match, :requested, competitable: season, assignments: [
        build(:assignment, player: current_player, side: 1),
        build(:assignment, player: opponent, side: 2)
      ])
    end

    subject { service.reject(match) }

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
      subject { service.finish(match, { "score" => "64" }) }

      it 'finishes the match' do
        expect { subject }.to change { match.reload.finished_at }.from(nil)
      end

      it 'sends notification to opponent' do
        expect(MatchFinishedNotifier).to receive(:with).with(hash_including(:record, :finished_by)).and_call_original
        expect_any_instance_of(MatchFinishedNotifier).to receive(:deliver).with(opponent)
        subject
      end

      it 'returns success result' do
        expect(subject).to be_success
      end
    end

    context 'with invalid score' do
      subject { service.finish(match, { "score" => "6" }) }

      it 'does not finish the match' do
        expect { subject }.not_to change { match.reload.finished_at }
      end

      it 'returns failure result' do
        expect(subject).to be_failure
      end

      it 'populates errors' do
        result = subject
        expect(result.errors).not_to be_empty
      end
    end
  end

  describe '#cancel' do
    let!(:match) do
      create(:match, :requested, :accepted, competitable: season, assignments: [
        build(:assignment, player: current_player, side: 1),
        build(:assignment, player: opponent, side: 2)
      ])
    end

    subject { service.cancel(match) }

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

  describe '#toggle_reaction' do
    let!(:match) { create(:match, competitable: season) }

    subject { service.toggle_reaction(match) }

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

  describe '#switch_prediction' do
    let!(:match) { create(:match, competitable: season) }

    context 'when no prediction exists' do
      subject { service.switch_prediction(match, 1) }

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
        subject { service.switch_prediction(match, 1) }

        it 'removes the prediction' do
          expect { subject }.to change(Prediction, :count).by(-1)
        end
      end

      context 'and switching to a different side' do
        subject { service.switch_prediction(match, 2) }

        it 'updates the prediction to new side' do
          expect { subject }.to change { existing_prediction.reload.side }.from(1).to(2)
        end
      end
    end
  end

  describe '#mark_notifications_read' do
    subject { service.mark_notifications_read(match) }

    let!(:match) { create(:match, competitable: season, requested_at: 2.days.ago, accepted_at: 1.day.ago) }
    let!(:notification) do
      Noticed::Notification.create!(recipient: current_player, seen_at: nil, read_at: nil,
                                    type: "MatchUpdatedNotifier::Notification",
                                    event: Noticed::Event.new(created_at: 50.days.ago, record: match, type: "MatchUpdatedNotifier"))
    end
    let!(:other_notification) do
      Noticed::Notification.create!(recipient: current_player, seen_at: nil, read_at: nil,
                                    type: "MatchUpdatedNotifier::Notification",
                                    event: Noticed::Event.new(created_at: 50.days.ago, record: build(:match, competitable: season), type: "MatchUpdatedNotifier"))
    end

    it 'marks all match notifications for the player as read' do
      expect {
        subject
      }.to change { notification.reload.read_at }.from(nil)
                                                 .and change { notification.reload.seen_at }.from(nil)
    end

    it 'does not mark other match notifications for the player as read' do
      expect {
        subject
      }.not_to change { other_notification.reload.read_at }
    end
  end
end
