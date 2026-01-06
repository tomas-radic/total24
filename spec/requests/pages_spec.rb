require 'rails_helper'

RSpec.describe "Pages", type: :request do
  describe "GET /about" do
    subject { get about_path }

    it "Returns http success" do
      subject

      expect(response).to have_http_status(:success)
    end
  end
  describe "GET /sitemap.xml" do
    it "returns http success and xml content" do
      get "/sitemap.xml"
      expect(response).to have_http_status(:success)
      expect(response.content_type).to include("application/xml")
      expect(response.body).to include("<urlset")
    end
  end
end
