require 'rails_helper'

RSpec.describe NotificationService do
  let!(:player) { create(:player) }
  let!(:match) { create(:match) }
  let!(:notification) do
    Noticed::Notification.create!(recipient: player, seen_at: nil, read_at: nil,
                                  type: "MatchUpdatedNotifier::Notification",
                                  event: Noticed::Event.new(created_at: 50.days.ago, record: match, type: "MatchUpdatedNotifier"))
  end
  let(:service) { NotificationService.new(player) }
  
  before do
    allow(Config).to receive(:notifications_max_age_days).and_return(30)
  end
  
  describe '#mark_as_read' do
    subject { service.mark_as_read(notification) }

    it 'updates seen_at and read_at timestamps' do
      expect {
        subject
      }.to change { notification.reload.seen_at }.from(nil).and change { notification.reload.read_at }.from(nil)
    end
  end
  
  describe '#mark_all_as_seen' do
    subject { service.mark_all_as_seen }

    let!(:other_notification) do
      Noticed::Notification.create!(recipient: create(:player), seen_at: nil, read_at: nil,
                                    type: "MatchUpdatedNotifier::Notification",
                                    event: Noticed::Event.new(created_at: 50.days.ago, record: match, type: "MatchUpdatedNotifier"))
    end

    it 'marks all player notifications as seen' do
      expect {
        subject
      }.to change { player.notifications.where(seen_at: nil).count }.from(1).to(0)
    end

    it 'does not mark other player notifications as seen' do
      expect {
        subject
      }.not_to change { other_notification.reload.seen_at }
    end
  end
  
  describe '#mark_all_as_read' do
    subject { service.mark_all_as_read }

    let!(:other_notification) do
      Noticed::Notification.create!(recipient: create(:player), seen_at: nil, read_at: nil,
                                    type: "MatchUpdatedNotifier::Notification",
                                    event: Noticed::Event.new(created_at: 10.days.ago, record: match, type: "MatchUpdatedNotifier"))
    end
    
    it 'marks all player notifications as seen and read' do
      expect {
        subject
      }.to change { player.notifications.where(seen_at: nil).count }.from(1).to(0)
       .and change { player.notifications.where(read_at: nil).count }.from(1).to(0)
    end
    
    it 'calls destroy_over_aged' do
      expect(service).to receive(:destroy_over_aged)
      subject
    end

    it 'does not mark other player notifications as seen or read' do
      expect {
        subject
      }.not_to change { other_notification.reload.seen_at }
    end
  end
  
  describe '#destroy_over_aged' do
    subject { service.destroy_over_aged }

    let!(:new_notification) do
      Noticed::Notification.create!(recipient: create(:player), seen_at: nil, read_at: nil,
                                    type: "MatchUpdatedNotifier::Notification",
                                    event: Noticed::Event.new(created_at: 1.hour.ago, record: match, type: "MatchUpdatedNotifier"))
    end

    it 'destroys notifications older than the configured age' do
      nid = notification.id
      expect {
        subject
      }.to change(Noticed::Event, :count)
      expect(Noticed::Notification.find_by(id: nid)).to be_nil
      expect(Noticed::Notification.find_by(id: new_notification.id)).not_to be_nil
    end
  end
end
