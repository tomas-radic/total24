require 'rails_helper'
require 'shared_examples/player_examples'

RSpec.describe "Player::Notifications", type: :request do
  let!(:player) { create(:player, name: "Player") }

  describe "GET /player/notifications" do
    subject { get player_notifications_path }

    it_behaves_like "player_request"

    context "When player is logged in" do

      before do
        sign_in player
      end

      it "Gives successful response" do
        subject

        expect(response).to have_http_status(:success)
        expect(response).to render_template(:index)
      end
    end
  end

  describe "POST /player/notifications/mark_all_read" do
    subject do
      post mark_all_read_player_notifications_path, headers: {
        "Accept" => "text/vnd.turbo-stream.html",
        "Content-Type" => "text/vnd.turbo-stream.html"
      }
    end

    it_behaves_like "player_request"

    context "When player is logged in" do
      before do
        sign_in player
      end

      let!(:match) { create(:match) }

      it "Marks all notifications as read and destroys all overaged" do
        Noticed::Notification.create!(recipient: create(:player), seen_at: nil, read_at: nil,
                                      type: "MatchUpdatedNotifier::Notification",
                                      event: Noticed::Event.new(created_at: 50.days.ago, record: match, type: "MatchUpdatedNotifier"))

        notification = Noticed::Notification.create!(recipient: player, seen_at: nil, read_at: nil,
                                                     type: "MatchUpdatedNotifier::Notification",
                                                     event: Noticed::Event.new(record: match, type: "MatchUpdatedNotifier"))

        expect {
          subject
        }.to change { Noticed::Notification.count }.from(2).to(1)

        notification.reload
        expect(notification.seen_at).not_to be_nil
        expect(notification.read_at).not_to be_nil
        expect(response).to have_http_status(:success)
      end
    end
  end
end
