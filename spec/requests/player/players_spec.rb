require 'rails_helper'

RSpec.describe "Player::Players", type: :request do
  before do
    get new_player_session_path
  end

  let!(:player) { create(:player, name: "Player", email: "player@somewhere.com") }

  describe "POST /player/players/anonymize" do
    subject { post player_players_anonymize_path, params: params }


    context "When player is logged in" do

      before do
        sign_in player
      end

      context "With matching confirmation email" do
        let(:params) do
          { confirmation_email: player.email }
        end

        it "Anonymizes player's attributes and redirects to root path" do
          subject

          player.reload
          expect(player.name).not_to eq("Player")
          expect(player.email).not_to eq("player@somewhere.com")
          expect(response).to redirect_to(root_path)
        end
      end

      context "With non-matching confirmation email" do
        let(:params) do
          { confirmation_email: "incorrect@somewhere.com" }
        end

        it "Does not anonymize player's attributes and redirects back to profile page" do
          expect_any_instance_of(Player).not_to(receive(:anonymize!))

          expect(subject).to redirect_to(edit_player_registration_path)
        end

      end
    end


    context "When player is NOT logged in" do
      let(:params) do
        { confirmation_email: player.email }
      end

      it "Redirects to login page" do
        expect(subject).to redirect_to new_player_session_path
      end
    end
  end


  describe "POST /player/players/toggle_open_to_play" do
    subject { post player_players_toggle_open_to_play_path }

    let!(:season) { create(:season) }

    it_behaves_like "player_request"

    context "when player is logged in" do
      before { sign_in player }

      context "when player is not currently open to play" do
        it "sets player as open to play" do
          expect {
            subject
          }.to change { player.reload.open_to_play_since }.from(nil)
          expect(response).to have_http_status(:success)
        end

        it "broadcasts the update" do
          expect(Turbo::StreamsChannel).to receive(:broadcast_update_to).twice
          subject
        end
      end

      context "when player is currently open to play" do
        before do
          player.update(open_to_play_since: 1.hour.ago)
        end

        it "removes player from open to play" do
          expect {
            subject
          }.to change { player.reload.open_to_play_since }.to(nil)
        end
      end

      context "when player has cant_play_since set" do
        before do
          player.update(cant_play_since: 1.hour.ago)
        end

        it "clears cant_play_since when setting open to play" do
          expect {
            subject
          }.to change { player.reload.cant_play_since }.to(nil)
                                                       .and change { player.reload.open_to_play_since }.from(nil)
        end
      end
    end

    context "When player is NOT logged in" do
      it "Redirects to login page" do
        expect(subject).to redirect_to new_player_session_path
      end
    end
  end


  describe "POST /player/players/toggle_cant_play" do
    subject { post player_players_toggle_cant_play_path }

    let!(:season) { create(:season) }

    it_behaves_like "player_request"

    context "when player is logged in" do
      before { sign_in player }

      context "when player can currently play" do
        it "sets player as cant play" do
          expect {
            subject
          }.to change { player.reload.cant_play_since }.from(nil)
          expect(response).to have_http_status(:success)
        end

        it "broadcasts the update" do
          expect(Turbo::StreamsChannel).to receive(:broadcast_update_to).twice
          subject
        end
      end

      context "when player currently cant play" do
        before do
          player.update(cant_play_since: 1.hour.ago)
        end

        it "removes cant play flag" do
          expect {
            subject
          }.to change { player.reload.cant_play_since }.to(nil)
        end
      end

      context "when player has open_to_play_since set" do
        before do
          player.update(open_to_play_since: 1.hour.ago)
        end

        it "clears open_to_play_since when setting cant play" do
          expect {
            subject
          }.to change { player.reload.open_to_play_since }.to(nil)
                                                          .and change { player.reload.cant_play_since }.from(nil)
        end
      end
    end

    context "When player is NOT logged in" do
      it "Redirects to login page" do
        expect(subject).to redirect_to new_player_session_path
      end
    end
  end
end
