shared_examples "manager_request" do |parameter|

  context "When manager is signed out, player is signed in" do

    before do
      sign_out manager
      sign_in player
    end

    it "Redirects to sign in path" do
      subject

      expect(response).to redirect_to new_manager_session_path
    end

  end
end
