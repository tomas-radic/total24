shared_examples "player_request" do |parameter|

  context "When player is signed in but is anonymized" do
    before do
      sign_in player
      player.update_column :anonymized_at, 1.minute.ago
    end

    it "Redirects to root path" do
      subject

      expect(response).to redirect_to root_path
    end
  end

  context "When player is signed out" do
    before do
      sign_out player
    end

    it "Redirects to sign in path" do
      subject

      expect(response).to redirect_to new_player_session_path
    end
  end

end
