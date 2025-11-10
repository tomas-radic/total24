require 'rails_helper'

RSpec.describe "Player::Matches", type: :request do
  before do
    get new_player_session_path
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
        it "calls MatchService#create and redirects on success" do
          service_double = instance_double(MatchService, create: true, match: build_stubbed(:match))
          allow(MatchService).to receive(:new).with(player).and_return(service_double)

          subject

          expect(service_double).to have_received(:create).with(season, requested_player)
          expect(response).to redirect_to(match_path(service_double.match))
        end

        it "calls MatchService#create and redirects on failure" do
          service_double = instance_double(MatchService, create: false, match: nil)
          allow(MatchService).to receive(:new).with(player).and_return(service_double)

          subject

          expect(service_double).to have_received(:create).with(season, requested_player)
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
      create(:match, :accepted, ranking_counted: true, competitable: season,
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
      create(:match, :requested, :accepted, competitable: season, ranking_counted: true,
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

      it "calls MatchService#update and redirects on success" do
        service_double = instance_double(MatchService, update: true)
        allow(MatchService).to receive(:new).with(player).and_return(service_double)

        subject

        expect(service_double).to have_received(:update).with(match, anything)
        expect(response).to redirect_to(match_path(match))
      end

      it "calls MatchService#update and renders edit on failure" do
        service_double = instance_double(MatchService, update: false)
        allow(MatchService).to receive(:new).with(player).and_return(service_double)

        subject

        expect(service_double).to have_received(:update).with(match, anything)
        expect(response).to render_template(:edit)
      end
    end

    context "when player is not authorized" do
      let!(:other_player) { create(:player) }
      before { sign_in other_player }

      it "does not call service" do
        expect(MatchService).not_to receive(:new)
        subject
      end
    end
  end

  describe "DELETE /player/matches/:id" do
    subject { delete player_match_path(match) }
    
    let!(:opponent) { create(:player, seasons: [season]) }
    let!(:match) do
      create(:match, :requested, competitable: season, ranking_counted: true,
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
      create(:match, :requested, competitable: season, ranking_counted: true,
             assignments: [
               build(:assignment, side: 1, player: player1),
               build(:assignment, side: 2, player: player2)
             ])
    end

    it_behaves_like "player_request"

    context "when logged in player is authorized (side 2)" do
      before { sign_in player2 }

      it "calls MatchService#accept and redirects on success" do
        service_double = instance_double(MatchService, accept: true, errors: [])
        allow(MatchService).to receive(:new).with(player2).and_return(service_double)

        subject

        expect(service_double).to have_received(:accept).with(match)
        expect(response).to redirect_to(match_path(match))
      end

      it "calls MatchService#accept and redirects with alert on failure" do
        service_double = instance_double(MatchService, accept: false, errors: ["Error message"])
        allow(MatchService).to receive(:new).with(player2).and_return(service_double)

        subject

        expect(service_double).to have_received(:accept).with(match)
        expect(response).to redirect_to(match_path(match))
      end
    end

    context "when logged in player is not authorized (side 1)" do
      before { sign_in player1 }

      it "does not call service" do
        expect(MatchService).not_to receive(:new)
        subject
      end
    end
  end

  describe "POST /player/matches/:id/reject" do
    subject { post reject_player_match_path(match) }
    
    let!(:match) do
      create(:match, :requested, competitable: season, ranking_counted: true,
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

      it "calls MatchService#reject and redirects" do
        service_double = instance_double(MatchService, reject: true, errors: [])
        allow(MatchService).to receive(:new).with(player2).and_return(service_double)

        subject

        expect(service_double).to have_received(:reject).with(match)
        expect(response).to redirect_to(match_path(match))
      end
    end

    context "when logged in player is not authorized" do
      let!(:other_player) { create(:player) }
      before { sign_in other_player }

      it "does not call service" do
        expect(MatchService).not_to receive(:new)
        subject
      end
    end
  end

  describe "GET /player/matches/:id/finish_init" do
    subject { get finish_init_player_match_path(match) }
    
    let!(:opponent) { create(:player, seasons: [season]) }
    let!(:match) do
      create(:match, :accepted, ranking_counted: true, competitable: season,
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
      let!(:other_player) { create(:player) }
      before { sign_in other_player }

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
      create(:match, :accepted, ranking_counted: true, competitable: season,
             assignments: [
               build(:assignment, player: player, side: 1),
               build(:assignment, player: opponent, side: 2)
             ])
    end
    let(:params) { { score: "64" } }

    it_behaves_like "player_request"

    context "when player is logged in and authorized" do
      before { sign_in player }

      it "calls MatchService#finish and redirects on success" do
        service_double = instance_double(MatchService, finish: true, errors: [])
        allow(MatchService).to receive(:new).with(player).and_return(service_double)

        subject

        expect(service_double).to have_received(:finish).with(match, hash_including("score" => "64"))
        expect(response).to redirect_to(match_path(match))
      end

      it "calls MatchService#finish and renders finish_init on failure" do
        service_double = instance_double(MatchService, finish: false, errors: ["Error"])
        allow(MatchService).to receive(:new).with(player).and_return(service_double)

        subject

        expect(service_double).to have_received(:finish).with(match, hash_including("score" => "64"))
        expect(response).to render_template(:finish_init)
      end
    end

    context "when player is not authorized" do
      let!(:other_player) { create(:player) }
      before { sign_in other_player }

      it "raises authorization error without calling service" do
        expect(MatchService).not_to receive(:new)
        subject
      end
    end
  end

  describe "POST /player/matches/:id/cancel" do
    subject { post cancel_player_match_path(match) }

    let!(:match) do
      create(:match, :accepted, competitable: season, ranking_counted: true,
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

      it "calls MatchService#cancel and redirects" do
        service_double = instance_double(MatchService, cancel: true, errors: [])
        allow(MatchService).to receive(:new).with(player2).and_return(service_double)

        subject

        expect(service_double).to have_received(:cancel).with(match)
        expect(response).to redirect_to(match_path(match))
      end
    end

    context "when player is not authorized" do
      let!(:other_player) { create(:player) }
      before { sign_in other_player }

      it "does not call service" do
        expect(MatchService).not_to receive(:new)
        subject
      end
    end
  end

  describe "POST /player/matches/:id/toggle_reaction" do
    subject { post toggle_reaction_player_match_path(match) }

    let!(:match) { create(:match, :accepted, competitable: season, ranking_counted: true) }

    it_behaves_like "player_request"

    context "when player is logged in" do
      before { sign_in player }

      it "calls MatchService#toggle_reaction and responds with turbo stream" do
        service_double = instance_double(MatchService, toggle_reaction: match)
        allow(MatchService).to receive(:new).with(player).and_return(service_double)

        subject

        expect(service_double).to have_received(:toggle_reaction).with(match)
        expect(response.media_type).to eq("text/vnd.turbo-stream.html")
      end
    end
  end

  describe "POST /player/matches/:id/switch_prediction" do
    subject { post switch_prediction_player_match_path(match), params: attributes }

    let!(:match) { create(:match, :accepted, competitable: season, ranking_counted: true) }
    let(:attributes) { { side: 2 } }

    it_behaves_like "player_request"

    context "when player is logged in and authorized" do
      before { sign_in player }

      it "calls MatchService#switch_prediction and responds with turbo stream" do
        service_double = instance_double(MatchService, switch_prediction: match)
        allow(MatchService).to receive(:new).with(player).and_return(service_double)

        subject

        expect(service_double).to have_received(:switch_prediction).with(match, "2")
        expect(response.media_type).to eq("text/vnd.turbo-stream.html")
      end
    end

    context "when match is reviewed (not authorized)" do
      before do
        match.update_columns(finished_at: 1.minute.ago, reviewed_at: 1.minute.ago)
        sign_in player
      end

      it "does not call service" do
        expect(MatchService).not_to receive(:new)
        subject
      end
    end

    context "when predictions are disabled (not authorized)" do
      before do
        match.update_column(:predictions_disabled_since, Time.now)
        sign_in player
      end

      it "does not call service" do
        expect(MatchService).not_to receive(:new)
        subject
      end
    end

    context "when match is not published" do
      before do
        match.update_column(:published_at, nil)
        sign_in player
      end

      it "does not call service" do
        expect(MatchService).not_to receive(:new)
        subject
      end
    end
  end
end
