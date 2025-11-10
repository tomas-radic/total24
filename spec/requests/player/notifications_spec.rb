require 'rails_helper'

RSpec.describe "Player::Notifications", type: :request do
  before do
    get new_player_session_path
  end

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

      it "calls NotificationService#mark_all_as_read" do
        service_double = instance_double(NotificationService, mark_all_as_read: true)
        expect(NotificationService).to receive(:new).with(player).and_return(service_double)

        subject

        expect(service_double).to have_received(:mark_all_as_read)
        expect(response).to have_http_status(:success)
      end
    end
  end
end
