require 'rails_helper'

RSpec.describe "Player::Enrollments", type: :request do
  let!(:player) { create(:player) }
  let!(:season) { create(:season) }

  describe "POST /player/enrollments" do
    subject { post player_enrollments_path, params: params }

    let(:params) { { agreement: "1" } }

    it_behaves_like "player_request"

    context "when player is logged in" do
      before { sign_in player }

      context "with agreement" do
        it "creates a new enrollment and sets rules_accepted_at" do
          expect { subject }.to change(Enrollment, :count).by(1)
          enrollment = Enrollment.last
          expect(enrollment.player).to eq(player)
          expect(enrollment.season).to eq(season)
          expect(enrollment.rules_accepted_at).to be_present
          expect(flash[:notice]).to eq("Pravidlá boli úspešne odsúhlasené.")
          expect(response).to redirect_to(root_path)
        end
      end

      context "without agreement" do
        let(:params) { { agreement: "0" } }

        it "does not create enrollment because rules_accepted_at is missing" do
          expect { subject }.not_to change(Enrollment, :count)
          expect(flash[:notice]).to eq("Nastala chyba, nepodarilo sa odsúhlasiť pravidlá.")
        end
      end

      context "when enrollment save fails" do
        before do
          allow_any_instance_of(Enrollment).to receive(:save).and_return(false)
        end

        it "does not create enrollment and shows error message" do
          expect { subject }.not_to change(Enrollment, :count)
          expect(flash[:notice]).to eq("Nastala chyba, nepodarilo sa odsúhlasiť pravidlá.")
          expect(response).to redirect_to(root_path)
        end
      end
    end
  end
end
