require 'rails_helper'

RSpec.describe "Player::Matches", type: :request do
  before do
    get new_player_session_path
    allow(Turbo::StreamsChannel).to receive(:broadcast_update_to)
  end

  let!(:season) { create(:season) }
  let!(:player) { create(:player, name: "Player", seasons: [season]) }

  describe "POST /player/matches" do
    subject { post player_matches_path, params: { player_id: requested_player.id } }

    let!(:requested_player) { create(:player, seasons: [season]) }

    it_behaves_like "player_request"

    context "when player is logged in" do
      before do
        sign_in player
      end

      context "when authorized" do
        it "creates new match and redirects" do
          expect { subject }.to change(Match, :count).by(1)
          expect(response).to redirect_to(match_path(Match.order(:created_at).last))
        end

        it 'sends a notification to the opponent' do
          expect(NewMatchNotifier).to receive(:with).with(hash_including(:record)).and_call_original
          expect_any_instance_of(NewMatchNotifier).to receive(:deliver).with(requested_player)
          subject
        end

        it "redirects to requested player when not saved" do
          # To cause failure, we can try to create a match with a player that doesn't exist or similar,
          # but here it's easier to just use a non-existent player_id or something that fails validation.
          # Matches::CreateService takes a requested_player object.
          # In the controller: @requested_player = Player.find(params[:player_id])
          # If we want it to reach service but fail, Match.save must be false.
          
          # Let's mock only the save call if we must, but the goal is "wherever possible".
          # If Match.save fails naturally, it's better.
          # Match validation: maybe missing season? but post goes to season-scoped matches.
          
          allow_any_instance_of(Match).to receive(:save).and_return(false)
          subject
          expect(response).to redirect_to(player_path(requested_player))
        end
      end

      context "when authorization fails" do
        before do
          allow_any_instance_of(MatchPolicy).to receive(:create?).and_return(false)
        end

        it "redirects to root" do
          subject
          expect(response).to redirect_to(root_path)
        end
      end
    end
  end

  describe "GET /player/matches/:id/edit" do
    subject { get edit_player_match_path(match) }

    let!(:opponent) { create(:player, seasons: [season]) }
    let!(:match) do
      create(:match, :accepted, season: season,
             assignments: [
               build(:assignment, side: 1, player: player),
               build(:assignment, side: 2, player: opponent)
             ])
    end

    it_behaves_like "player_request"

    context "when player is logged in and authorized" do
      before do
        sign_in player
      end

      it "renders edit template" do
        subject
        expect(response).to render_template(:edit)
      end
    end

    context "when player is not authorized" do
      let!(:other_player) { create(:player) }
      before { sign_in other_player }

      it "redirects to root" do
        subject
        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe "PATCH /player/matches/:id" do
    subject { patch player_match_path(match), params: params }
    
    let!(:opponent) { create(:player, seasons: [season]) }
    let!(:match) do
      create(:match, :accepted, season: season,
             assignments: [
               build(:assignment, side: 1, player: player),
               build(:assignment, side: 2, player: opponent)
             ])
    end
    let(:params) do
      {
        match: {
          play_date: Date.tomorrow.to_s,
          play_time: Match.play_times.keys.sample,
          notes: "A note about this match.",
          place_id: create(:place).id
        }
      }
    end

    it_behaves_like "player_request"

    context "when player is logged in and authorized" do
      before { sign_in player }

      it "updates match and redirects" do
        expect(Turbo::StreamsChannel).to receive(:broadcast_update_to).with(
          "match_#{match.id}_for_player_#{player.id}",
          hash_including(target: "match_#{match.id}")
        )
        expect(Turbo::StreamsChannel).to receive(:broadcast_update_to).with(
          "match_#{match.id}_for_player_#{opponent.id}",
          hash_including(target: "match_#{match.id}")
        )

        expect(MatchUpdatedNotifier).to receive(:with).with(hash_including(record: match)).and_call_original
        expect_any_instance_of(MatchUpdatedNotifier).to receive(:deliver).with([opponent])

        subject

        expect(match.reload.notes).to eq("A note about this match.")
        expect(response).to redirect_to(match_path(match))
      end

      it "renders edit template when not saved" do
        allow_any_instance_of(Match).to receive(:update).and_return(false)

        subject

        expect(response).to render_template(:edit)
      end
    end

    context "when player is not authorized" do
      let!(:other_player) { create(:player) }
      before { sign_in other_player }

      it "does not call service" do
        expect(Matches::UpdateService).not_to receive(:new)
        subject
      end
    end
  end

  describe "DELETE /player/matches/:id" do
    subject { delete player_match_path(match) }
    
    let!(:opponent) { create(:player, seasons: [season]) }
    let!(:match) do
      create(:match, season: season,
             assignments: [
               build(:assignment, side: 1, player: player),
               build(:assignment, side: 2, player: opponent)
             ])
    end

    it_behaves_like "player_request"

    context "when player is logged in and authorized" do
      before { sign_in player }

      it "destroys the match and redirects" do
        match_id = match.id

        subject
        expect(response).to redirect_to(root_path)
        expect { Match.find(match_id) }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context "when player is not authorized" do
      let!(:other_player) { create(:player) }
      before { sign_in other_player }

      it "does not destroy the match and redirects" do
        subject
        expect(response).to redirect_to(root_path)
        expect(Match.find(match.id)).to be_present
      end
    end
  end

  describe "POST /player/matches/:id/accept" do
    subject { post accept_player_match_path(match) }

    let!(:player1) { create(:player, seasons: [season]) }
    let!(:player2) { create(:player, seasons: [season]) }
    let!(:match) do
      create(:match, season: season,
             assignments: [
               build(:assignment, side: 1, player: player1),
               build(:assignment, side: 2, player: player2)
             ])
    end

    it_behaves_like "player_request"

    context "when logged in player is authorized (side 2)" do
      before { sign_in player2 }

      it "accepts the match and redirects" do
        expect(Turbo::StreamsChannel).to receive(:broadcast_update_to).with(
          "players_open_to_play",
          hash_including(target: "players_open_to_play")
        )
        expect(Turbo::StreamsChannel).to receive(:broadcast_update_to).with(
          "players_open_to_play",
          hash_including(target: "players_open_to_play_top")
        )
        expect(Turbo::StreamsChannel).to receive(:broadcast_update_to).with(
          "match_#{match.id}_for_player_#{player1.id}",
          hash_including(target: "match_#{match.id}")
        )
        expect(Turbo::StreamsChannel).to receive(:broadcast_update_to).with(
          "match_#{match.id}_for_player_#{player2.id}",
          hash_including(target: "match_#{match.id}")
        )
        expect(MatchAcceptedNotifier).to receive(:with).with(hash_including(record: match)).and_call_original
        expect_any_instance_of(MatchAcceptedNotifier).to receive(:deliver).with(player1)

        subject

        expect(match.reload.accepted_at).to be_present
        expect(response).to redirect_to(match_path(match))
      end

      it "redirects to match show page with alert on failure" do
        allow_any_instance_of(Match).to receive(:update!).and_return(false)
        allow_any_instance_of(ActiveModel::Errors).to receive(:full_messages).and_return(["Error message"])

        subject

        expect(response).to redirect_to(match_path(match))
        expect(flash[:alert]).to eq("Error message")
      end
    end

    context "when logged in player is not authorized (side 1)" do
      before { sign_in player1 }

      it "does not call service" do
        expect(Matches::AcceptService).not_to receive(:new)
        subject
      end
    end
  end

  describe "POST /player/matches/:id/reject" do
    subject { post reject_player_match_path(match) }
    
    let!(:match) do
      create(:match, season: season,
             assignments: [
               build(:assignment, side: 1, player: player1),
               build(:assignment, side: 2, player: player2)
             ])
    end
    let!(:player1) { create(:player, seasons: [season]) }
    let!(:player2) { create(:player, seasons: [season]) }

    it_behaves_like "player_request"

    context "when logged in player is authorized (side 2)" do
      before { sign_in player2 }

      it "rejects the match and redirects" do
        expect(Turbo::StreamsChannel).to receive(:broadcast_update_to).with(
          "match_#{match.id}_for_player_#{player1.id}",
          hash_including(target: "match_#{match.id}")
        )
        expect(Turbo::StreamsChannel).to receive(:broadcast_update_to).with(
          "match_#{match.id}_for_player_#{player2.id}",
          hash_including(target: "match_#{match.id}")
        )
        expect(MatchRejectedNotifier).to receive(:with).with(hash_including(record: match)).and_call_original
        expect_any_instance_of(MatchRejectedNotifier).to receive(:deliver).with(player1)

        subject

        expect(match.reload.rejected_at).to be_present
        expect(response).to redirect_to(match_path(match))
      end
    end

    context "when logged in player is not authorized" do
      let!(:other_player) { create(:player) }
      before { sign_in other_player }

      it "does not call service" do
        expect(Matches::RejectService).not_to receive(:new)
        subject
      end
    end
  end

  describe "GET /player/matches/:id/finish_init" do
    subject { get finish_init_player_match_path(match) }
    
    let!(:opponent) { create(:player, seasons: [season]) }
    let!(:match) do
      create(:match, :accepted, season: season,
             assignments: [
               build(:assignment, player: player, side: 1),
               build(:assignment, player: opponent, side: 2)
             ])
    end

    it_behaves_like "player_request"

    context "when player is logged in and authorized" do
      before { sign_in player }

      it "renders finish_init template" do
        subject
        expect(response).to render_template(:finish_init)
      end
    end

    context "when player is not authorized" do
      before { sign_in create(:player) }

      it "redirects to root" do
        subject
        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe "POST /player/matches/:id/finish" do
    subject { post finish_player_match_path(match), params: }

    let!(:opponent) { create(:player, seasons: [season]) }
    let!(:match) do
      create(:match, :accepted, season: season,
             assignments: [
               build(:assignment, player: player, side: 1),
               build(:assignment, player: opponent, side: 2)
             ])
    end
    let(:params) { { score: "64" } }

    it_behaves_like "player_request"

    context "when player is logged in and authorized" do
      before { sign_in player }

      it "finishes the match and redirects" do
        expect(Turbo::StreamsChannel).to receive(:broadcast_update_to).with(
          "match_#{match.id}_for_player_#{player.id}",
          hash_including(target: "match_#{match.id}")
        )
        expect(Turbo::StreamsChannel).to receive(:broadcast_update_to).with(
          "match_#{match.id}_for_player_#{opponent.id}",
          hash_including(target: "match_#{match.id}")
        )
        expect(MatchFinishedNotifier).to receive(:with).with(hash_including(record: match, finished_by: player)).and_call_original
        expect_any_instance_of(MatchFinishedNotifier).to receive(:deliver).with(opponent)

        subject

        match.reload
        expect(match.finished_at).to be_present
        expect(match.set1_side1_score).to eq(6)
        expect(match.set1_side2_score).to eq(4)
        expect(response).to redirect_to(match_path(match))
      end

      it "renders finish_init template when score is invalid" do
        params[:score] = "060"

        subject

        expect(response).to render_template(:finish_init)
      end
    end

    context "when player is not authorized" do
      let!(:other_player) { create(:player) }
      before { sign_in other_player }

      it "raises authorization error without calling service" do
        expect(Matches::FinishService).not_to receive(:new)
        subject
      end
    end
  end

  describe "POST /player/matches/:id/cancel" do
    subject { post cancel_player_match_path(match) }

    let!(:match) do
      create(:match, :accepted, season: season,
             assignments: [
               build(:assignment, side: 1, player: player1),
               build(:assignment, side: 2, player: player2)
             ])
    end
    let!(:player1) { create(:player, seasons: [season]) }
    let!(:player2) { create(:player, seasons: [season]) }

    it_behaves_like "player_request"

    context "when logged in player is authorized" do
      before { sign_in player2 }

      it "cancels the match and redirects" do
        expect(Turbo::StreamsChannel).to receive(:broadcast_update_to).with(
          "match_#{match.id}_for_player_#{player1.id}",
          hash_including(target: "match_#{match.id}")
        )
        expect(Turbo::StreamsChannel).to receive(:broadcast_update_to).with(
          "match_#{match.id}_for_player_#{player2.id}",
          hash_including(target: "match_#{match.id}")
        )

        expect(MatchCanceledNotifier).to receive(:with).with(hash_including(record: match)).and_call_original
        expect_any_instance_of(MatchCanceledNotifier).to receive(:deliver).with([player1])

        subject

        expect(match.reload.canceled_at).to be_present
        expect(response).to redirect_to(match_path(match))
      end
    end

    context "when player is not authorized" do
      let!(:other_player) { create(:player) }
      before { sign_in other_player }

      it "does not call service" do
        expect(Matches::CancelService).not_to receive(:new)
        subject
      end
    end
  end

  describe "POST /player/matches/:id/toggle_reaction" do
    subject { post toggle_reaction_player_match_path(match) }

    let!(:match) { create(:match, :accepted, season: season) }

    it_behaves_like "player_request"

    context "when player is logged in" do
      before { sign_in player }

      it "creates reaction for the match" do
        expect { subject }.to change(match.reactions, :count).by(1)
        expect(response.media_type).to eq("text/vnd.turbo-stream.html")
      end
    end
  end

  describe "POST /player/matches/:id/switch_prediction" do
    subject { post switch_prediction_player_match_path(match), params: attributes }

    let!(:match) { create(:match, :accepted, season: season) }
    let(:attributes) { { side: 2 } }

    it_behaves_like "player_request"

    context "when player is logged in and authorized" do
      before { sign_in player }

      it "creates prediction for the match" do
        expect { subject }.to change(match.predictions, :count).by(1)
        expect(response.media_type).to eq("text/vnd.turbo-stream.html")
      end
    end

    context "when match is reviewed (not authorized)" do
      before do
        match.update!(finished_at: 1.minute.ago, reviewed_at: 1.minute.ago,
                      winner_side: 1, set1_side1_score: 6, set1_side2_score: 3)
        sign_in player
      end

      it "does not call service" do
        expect(Matches::SwitchPredictionService).not_to receive(:new)
        subject
      end
    end

    context "when predictions are disabled (not authorized)" do
      before do
        match.update!(predictions_disabled_since: Time.current)
        sign_in player
      end

      it "does not call service" do
        expect(Matches::SwitchPredictionService).not_to receive(:new)
        subject
      end
    end

    context "when match is not published" do
      before do
        match.update!(published_at: nil)
        sign_in player
      end

      it "does not call service" do
        expect(Matches::SwitchPredictionService).not_to receive(:new)
        subject
      end
    end
  end
end
