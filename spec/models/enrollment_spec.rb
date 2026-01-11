require 'rails_helper'

RSpec.describe Enrollment, type: :model do
  describe ".active" do
    let(:player) { create(:player) }
    let(:season) { create(:season) }

    it "includes active enrollments" do
      enrollment = create(:enrollment, :active, player: player, season: season)
      expect(Enrollment.active).to include(enrollment)
    end

    it "excludes canceled enrollments" do
      enrollment = create(:enrollment, :active, player: player, season: season, canceled_at: Time.current)
      expect(Enrollment.active).not_to include(enrollment)
    end

    it "excludes enrollments without rules accepted" do
      enrollment = create(:enrollment, player: player, season: season, rules_accepted_at: nil, fee_amount_paid: 30)
      expect(Enrollment.active).not_to include(enrollment)
    end

    it "excludes enrollments without fee paid" do
      enrollment = create(:enrollment, player: player, season: season, rules_accepted_at: Time.current, fee_amount_paid: nil)
      expect(Enrollment.active).not_to include(enrollment)
    end

    it "excludes enrollments with inactive player" do
      inactive_player = create(:player, confirmed_at: nil)
      enrollment = create(:enrollment, :active, player: inactive_player, season: season)
      expect(Enrollment.active).not_to include(enrollment)
    end

    it "excludes enrollments with anonymized player" do
      anonymized_player = create(:player, anonymized_at: Time.current)
      enrollment = create(:enrollment, :active, player: anonymized_player, season: season)
      expect(Enrollment.active).not_to include(enrollment)
    end
  end

  describe "#active?" do
    let(:player) { create(:player) }
    let(:season) { create(:season) }

    it "returns true for active enrollment" do
      enrollment = create(:enrollment, :active, player: player, season: season)
      expect(enrollment.active?).to be true
    end

    it "returns false for canceled enrollment" do
      enrollment = create(:enrollment, :active, player: player, season: season, canceled_at: Time.current)
      expect(enrollment.active?).to be false
    end

    it "returns false for enrollment without rules accepted" do
      enrollment = create(:enrollment, player: player, season: season, rules_accepted_at: nil, fee_amount_paid: 30)
      expect(enrollment.active?).to be false
    end

    it "returns false for enrollment without fee paid" do
      enrollment = create(:enrollment, player: player, season: season, rules_accepted_at: Time.current, fee_amount_paid: nil)
      expect(enrollment.active?).to be false
    end

    it "returns false for enrollment with inactive player" do
      inactive_player = create(:player, confirmed_at: nil)
      enrollment = create(:enrollment, :active, player: inactive_player, season: season)
      expect(enrollment.active?).to be false
    end

    it "returns false for enrollment with anonymized player" do
      anonymized_player = create(:player, anonymized_at: Time.current)
      enrollment = create(:enrollment, :active, player: anonymized_player, season: season)
      expect(enrollment.active?).to be false
    end
  end
end
