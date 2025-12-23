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

      context 'with another player who commented' do
        let!(:other_player) { create(:player) }
        let!(:comment) { create(:comment, commentable: match, player: other_player) }

        subject { service.call(match, { notes: "Updated" }) }

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
end
