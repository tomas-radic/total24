require 'rails_helper'
require 'shared_examples/manager_examples'

RSpec.describe "Manager::Articles", type: :request do

  let!(:manager) { create(:manager) }
  let!(:player) { create(:player, email: manager.email) } # used in shared examples

  describe "GET /manager/articles" do
    subject { get manager_articles_path }

    it_behaves_like "manager_request"

    context "As a logged in manager" do
      before { sign_in manager }

      it "Renders page" do
        subject

        expect(response).to render_template(:index)
        expect(response).to have_http_status(:success)
        expect(assigns(:articles)).to be_nil
        expect(response.body).to include(new_manager_season_path)
        expect(response.body).not_to include(new_manager_article_path)
      end

      context "With existing season" do
        let!(:season) { create(:season) }

        it "Renders page" do
          subject

          expect(response).to render_template(:index)
          expect(response).to have_http_status(:success)
          expect(assigns(:articles)).to be_empty
          expect(response.body).to include(new_manager_article_path)
          expect(response.body).not_to include(new_manager_season_path)
        end

        context "With articles" do
          before { create_list(:article, 3, season: season) }

          it "Renders page" do
            subject

            expect(assigns(:articles)).not_to be_empty
            expect(response).to render_template(:index)
            expect(response).to have_http_status(:success)
          end
        end
      end
    end
  end


  describe "GET /managers/articles/new" do
    subject { get new_manager_article_path }

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


  describe "POST /manager/articles" do
    subject { post manager_articles_path(params: params) }

    let!(:season) { create(:season) }

    let(:valid_params) do
      {
        article: {
          title: "Title",
          content: "Content."
        }
      }
    end
    let(:invalid_params) do
      {
        article: {
          title: "",
          content: "Content.",
        }
      }
    end

    context "As a logged in manager" do
      before { sign_in manager }

      let!(:season) { create(:season) }

      context "With valid params" do
        let(:params) { valid_params }

        it_behaves_like "manager_request"

        it "Creates article and redirects" do
          subject

          expect(Article.order(created_at: :desc).first).to have_attributes(valid_params[:article])
          expect(response).to redirect_to(manager_articles_path)
        end
      end

      context "With invalid params" do
        let(:params) { invalid_params }

        it_behaves_like "manager_request"

        it "Renders new" do
          subject

          expect(Article.count).to eq(0)
          expect(response).to render_template(:new)
        end
      end
    end
  end


  describe "GET /manager/articles/:id" do
    subject { get edit_manager_article_path(article) }

    let!(:season) { create(:season) }

    context "As a logged in manager" do
      before { sign_in manager }

      let!(:article) { create(:article, season: season) }

      it_behaves_like "manager_request"

      it "Renders page" do
        subject

        expect(response).to render_template(:edit)
      end
    end
  end


  describe "PATCH /manager/articles/:id" do
    subject { patch manager_article_path(article, params: params) }

    let!(:season) { create(:season) }

    let(:valid_params) { { article: { title: "Title" } } }
    let(:invalid_params) { { article: { title: "" } } }

    context "As a logged in manager" do
      before { sign_in manager }

      let!(:article) { create(:article, season: season) }

      context "With valid params" do
        let(:params) { valid_params }

        it_behaves_like "manager_request"

        it "Updates article and redirects" do
          subject

          article.reload
          expect(article.title).to eq(valid_params[:article][:title])
          expect(response).to redirect_to(manager_articles_path)
        end
      end

      context "With invalid params" do
        let(:params) { invalid_params }

        it_behaves_like "manager_request"

        it "Renders edit" do
          subject

          article.reload
          expect(article.title).not_to eq(valid_params[:title])
          expect(response).to render_template(:edit)
        end
      end
    end
  end


  describe "DELETE /manager/articles/:id" do
    subject { delete manager_article_path(article) }

    let!(:season) { create(:season) }

    context "As a logged in manager" do
      before { sign_in manager }

      let!(:article) { create(:article, title: "Title", season: season) }

      it_behaves_like "manager_request"

      it "Destroys article" do
        subject

        expect(response).to redirect_to(manager_articles_path)
        expect(Article.find_by(title: "Title")).to be_nil
      end
    end
  end
end
