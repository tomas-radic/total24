require 'rails_helper'
require 'shared_examples/manager_examples'

RSpec.describe "Manager::Tournaments", type: :request do

  let!(:manager) { create(:manager) }
  let!(:player) { create(:player, email: manager.email) } # used in shared examples

  describe "GET /manager/tournaments" do
    subject { get manager_tournaments_path }

    it_behaves_like "manager_request"

    context "As a logged in manager" do
      before { sign_in manager }

      it "Renders page" do
        subject

        expect(response).to render_template(:index)
        expect(response).to have_http_status(:success)
        expect(assigns(:tournaments)).to be_nil
        expect(response.body).to include(new_manager_season_path)
        expect(response.body).not_to include(new_manager_tournament_path)
      end

      context "With existing season" do
        let!(:season) { create(:season) }

        it "Renders page" do
          subject

          expect(response).to render_template(:index)
          expect(response).to have_http_status(:success)
          expect(assigns(:tournaments)).to be_empty
          expect(response.body).to include(new_manager_tournament_path)
          expect(response.body).not_to include(new_manager_season_path)
        end

        context "With tournaments" do
          before { create_list(:tournament, 3, season: season) }

          it "Renders page" do
            subject

            expect(assigns(:tournaments)).not_to be_empty
            expect(response).to render_template(:index)
            expect(response).to have_http_status(:success)
          end
        end
      end
    end
  end


  describe "GET /managers/tournaments/new" do
    subject { get new_manager_tournament_path }

    let!(:season) { create(:season) }

    it_behaves_like "manager_request"

    context "As a logged in manager" do
      before { sign_in manager }

      it "Renders page" do
        subject

        expect(response).to render_template(:new)
      end
    end
  end


  describe "POST /manager/tournaments" do
    subject { post manager_tournaments_path(params: params) }

    let!(:season) { create(:season) }

    let(:valid_params) do
      {
        tournament: {
          name: "Name",
          main_info: "Main info."
        }
      }
    end
    let(:invalid_params) do
      {
        tournament: {
          name: "",
          main_info: "Main info.",
        }
      }
    end

    context "As a logged in manager" do
      before { sign_in manager }

      let!(:season) { create(:season) }

      context "With valid params" do
        let(:params) { valid_params }

        it_behaves_like "manager_request"

        it "Creates tournament and redirects" do
          subject

          expect(Tournament.order(created_at: :desc).first).to have_attributes(valid_params[:tournament])
          expect(response).to redirect_to(manager_tournaments_path)
        end
      end

      context "With invalid params" do
        let(:params) { invalid_params }

        it_behaves_like "manager_request"

        it "Renders new" do
          subject

          expect(Tournament.count).to eq(0)
          expect(response).to render_template(:new)
        end
      end
    end
  end


  describe "GET /manager/tournaments/:id" do
    subject { get edit_manager_tournament_path(tournament) }

    let!(:season) { create(:season) }

    context "As a logged in manager" do
      before { sign_in manager }

      let!(:tournament) { create(:tournament, season: season) }

      it_behaves_like "manager_request"

      it "Renders page" do
        subject

        expect(response).to render_template(:edit)
      end
    end
  end


  describe "PATCH /manager/tournaments/:id" do
    subject { patch manager_tournament_path(tournament, params: params) }

    let!(:season) { create(:season) }

    let(:valid_params) { { tournament: { name: "Name" } } }
    let(:invalid_params) { { tournament: { name: "" } } }

    context "As a logged in manager" do
      before { sign_in manager }

      let!(:tournament) { create(:tournament, season: season) }

      context "With valid params" do
        let(:params) { valid_params }

        it_behaves_like "manager_request"

        it "Updates tournament and redirects" do
          subject

          tournament.reload
          expect(tournament.name).to eq(valid_params[:tournament][:name])
          expect(response).to redirect_to(manager_tournaments_path)
        end
      end

      context "With invalid params" do
        let(:params) { invalid_params }

        it_behaves_like "manager_request"

        it "Renders edit" do
          subject

          tournament.reload
          expect(tournament.name).not_to eq(valid_params[:name])
          expect(response).to render_template(:edit)
        end
      end
    end
  end
end
