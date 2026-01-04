require 'rails_helper'
require 'shared_examples/manager_examples'

RSpec.describe "Manager::Seasons", type: :request do
  let!(:manager) { create(:manager) }
  let!(:player) { create(:player, email: manager.email) }
  let!(:season) { create(:season) }

  describe "GET /manager/seasons/:id/edit" do
    subject { get edit_manager_season_path(season) }

    it_behaves_like "manager_request"

    context "As a logged in manager" do
      before { sign_in manager }

      it "renders the edit template" do
        subject
        expect(response).to have_http_status(:success)
        expect(response).to render_template(:edit)
      end
    end
  end

  describe "PATCH /manager/seasons/:id" do
    let(:params) { { season: { name: "Updated Season Name" } } }
    subject { patch manager_season_path(season), params: params }

    it_behaves_like "manager_request"

    context "As a logged in manager" do
      before { sign_in manager }

      context "with valid parameters" do
        it "updates the season and redirects to dashboard" do
          expect { subject }.to change { season.reload.name }.to("Updated Season Name")
          expect(response).to redirect_to(manager_pages_dashboard_path)
        end
      end

      context "with invalid parameters" do
        let(:params) { { season: { name: "" } } }

        it "does not update the season and renders edit" do
          expect { subject }.not_to change { season.reload.name }
          expect(response).to have_http_status(:unprocessable_content)
          expect(response).to render_template(:edit)
        end
      end
    end
  end

  describe "POST /manager/seasons/open_new" do
    subject { post open_new_manager_seasons_path }

    it_behaves_like "manager_request"

    context "As a logged in manager" do
      before { sign_in manager }

      it "creates a new season and redirects to dashboard" do
        season.update!(ended_at: Time.current)
        expect { subject }.to change(Season, :count).by(1)
        expect(response).to redirect_to(manager_pages_dashboard_path)
        follow_redirect!
        expect(response.body).to include("Nová sezóna bola otvorená.")
      end

      context "when a season already exists" do
        it "duplicates the current managed season settings" do
          season.update!(max_pending_matches: 5, ended_at: Time.current)
          subject
          new_season = Season.sorted.first
          expect(new_season.max_pending_matches).to eq(5)
          expect(new_season.id).not_to eq(season.id)
          expect(new_season.ended_at).to be_nil
        end
      end

      context "when no season exists" do
        before { Season.delete_all }

        it "creates a new season with default settings" do
          expect { subject }.to change(Season, :count).by(1)
          expect(response).to redirect_to(manager_pages_dashboard_path)
          new_season = Season.first
          expect(new_season.name).to be_present
        end
      end
    end
  end
end
