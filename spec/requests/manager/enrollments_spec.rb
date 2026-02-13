require 'rails_helper'
require 'shared_examples/manager_examples'

RSpec.describe "Manager::Enrollments", type: :request do

  describe "POST /manager/enrollments" do
    let!(:season) { create(:season, ended_at: nil) }
    let!(:manager) { create(:manager) }
    let!(:player) { create(:player) }

    before { sign_in manager }

    it "creates an enrollment" do
      expect {
        post manager_enrollments_path, params: { enrollment: { player_id: player.id } }
      }.to change(Enrollment, :count).by(1)
      expect(Enrollment.last.rules_accepted_at).not_to be_nil
      expect(response).to redirect_to(manager_pages_dashboard_path)
    end
  end

  describe "PATCH /manager/enrollments/:id" do
    let!(:season) { create(:season, ended_at: nil) }
    let!(:manager) { create(:manager) }
    let!(:enrollment) { create(:enrollment, season: season) }

    before { sign_in manager }

    it "updates an enrollment" do
      patch manager_enrollment_path(enrollment), params: { enrollment: { fee_amount_paid: 100, canceled_at: Time.current } }
      enrollment.reload
      expect(enrollment.fee_amount_paid).to eq(100)
      expect(enrollment.canceled_at).not_to be_nil
      expect(response).to redirect_to(manager_pages_dashboard_path)
    end

    it "does not update rules_accepted_at" do
      old_accepted_at = enrollment.rules_accepted_at
      patch manager_enrollment_path(enrollment), params: { enrollment: { rules_accepted_at: 1.day.from_now } }
      expect(enrollment.reload.rules_accepted_at).to be_within(1.second).of(old_accepted_at)
    end

    it "allows setting fee_amount_paid to nil" do
      patch manager_enrollment_path(enrollment), params: { enrollment: { fee_amount_paid: nil } }
      expect(enrollment.reload.fee_amount_paid).to be_nil
    end
  end

end
