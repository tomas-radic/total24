require 'rails_helper'

RSpec.describe Matches::MarkNotificationsReadService do
  let!(:current_player) { create(:player) }
  let!(:season) { create(:season) }
  let(:service) { Matches::MarkNotificationsReadService.new(current_player) }

  describe '#call' do
    subject { service.call(match) }

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
