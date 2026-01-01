require "rails_helper"
require "pundit/rspec"

describe MatchPolicy do
  subject { described_class }

  let!(:season) { create(:season) }
  let!(:player) { create(:player, seasons: [season]) }
  let!(:match) { create(:match, season:) }

  
  permissions :edit?, :update? do
    before do
      match.assignments = [
        build(:assignment, player: player, side: 1),
        build(:assignment, player: create(:player, seasons: [season]), side: 2)
      ]
    end

    context "With conditions met" do
      before { match.update!(accepted_at: Time.current) }

      it "Permits" do
        expect(subject).to permit(player, match)
      end
    end

    context "When season has ended" do
      before { match.season.update!(ended_at: 2.days.ago) }

      it "Does not permit" do
        expect(subject).not_to permit(player, match)
      end
    end

    context "When match has not been accepted" do
      before { match.update!(accepted_at: nil) }

      it "Does not permit" do
        expect(subject).not_to permit(player, match)
      end
    end

    context "When player is not assigned to the match" do
      before do
        match.assignments = [
          build(:assignment, player: create(:player, seasons: [season]), side: 1),
          build(:assignment, player: create(:player, seasons: [season]), side: 2)
        ]
      end

      it "Does not permit" do
        expect(subject).not_to permit(player, match)
      end
    end
  end


  permissions :destroy? do
    before do
      match.assignments = [
        build(:assignment, player: player, side: 1),
        build(:assignment, player: create(:player, seasons: [season]), side: 2)
      ]
    end

    context "With conditions met" do
      it "Permits" do
        expect(subject).to permit(player, match)
      end
    end

    context "When season has ended" do
      before { match.season.update!(ended_at: 2.days.ago) }

      it "Does not permit" do
        expect(subject).not_to permit(player, match)
      end
    end

    context "When match has been reviewed" do
      before { match.update!(accepted_at: 1.minute.ago, finished_at: 1.minute.ago, reviewed_at: 1.minute.ago,
                             winner_side: 1, set1_side1_score: 6, set1_side2_score: 3) }

      it "Does not permit" do
        expect(subject).not_to permit(player, match)
      end
    end

    context "When match has been accepted" do
      before { match.update!(accepted_at: 1.minute.ago) }

      it "Does not permit" do
        expect(subject).not_to permit(player, match)
      end
    end

    context "When match has been rejected" do
      before { match.update!(rejected_at: 1.minute.ago) }

      it "Does not permit" do
        expect(subject).not_to permit(player, match)
      end
    end

    context "When player is assigned as a side 2" do
      before do
        match.assignments = [
          build(:assignment, player: create(:player, seasons: [season]), side: 1),
          build(:assignment, player: player, side: 2)
        ]
      end

      it "Does not permit" do
        expect(subject).not_to permit(player, match)
      end
    end

    context "When player is not assigned to the match" do
      before do
        match.assignments = [
          build(:assignment, player: create(:player, seasons: [season]), side: 1),
          build(:assignment, player: create(:player, seasons: [season]), side: 2)
        ]
      end

      it "Does not permit" do
        expect(subject).not_to permit(player, match)
      end
    end
  end


  permissions :accept?, :reject? do
    before do
      match.assignments = [
        build(:assignment, player: create(:player, seasons: [season]), side: 1),
        build(:assignment, player: player, side: 2)
      ]
    end

    context "With conditions met" do
      it "Permits" do
        expect(subject).to permit(player, match)
      end
    end

    context "When season has ended" do
      before { match.season.update!(ended_at: 2.days.ago) }

      it "Does not permit" do
        expect(subject).not_to permit(player, match)
      end
    end

    context "When match has been reviewed" do
      before { match.update!(accepted_at: 1.minute.ago, finished_at: 1.minute.ago, reviewed_at: 1.minute.ago,
                             winner_side: 1, set1_side1_score: 6, set1_side2_score: 3) }

      it "Does not permit" do
        expect(subject).not_to permit(player, match)
      end
    end

    context "When player is assigned as a side 1" do
      before do
        match.assignments = [
          build(:assignment, player: player, side: 1),
          build(:assignment, player: create(:player, seasons: [season]), side: 2)
        ]
      end

      it "Does not permit" do
        expect(subject).not_to permit(player, match)
      end
    end

    context "When player is not assigned to the match" do
      before do
        match.assignments = [
          build(:assignment, player: create(:player, seasons: [season]), side: 1),
          build(:assignment, player: create(:player, seasons: [season]), side: 2)
        ]
      end

      it "Does not permit" do
        expect(subject).not_to permit(player, match)
      end
    end
  end


  permissions :finish_init?, :finish? do
    before do
      match.assignments = [
        build(:assignment, player: player, side: 1),
        build(:assignment, player: create(:player, seasons: [season]), side: 2)
      ]
    end

    context "With conditions met" do
      before { match.update!(accepted_at: 1.hour.ago) }

      it "Permits" do
        expect(subject).to permit(player, match)
      end
    end

    context "When season has ended" do
      before { match.season.update!(ended_at: 2.days.ago) }

      it "Does not permit" do
        expect(subject).not_to permit(player, match)
      end
    end

    context "When match has not been accepted" do
      before { match.update!(accepted_at: nil) }

      it "Does not permit" do
        expect(subject).not_to permit(player, match)
      end
    end

    context "When match has been rejected" do
      before { match.update!(rejected_at: 1.hour.ago) }

      it "Does not permit" do
        expect(subject).not_to permit(player, match)
      end
    end

    context "When match has been reviewed" do
      before { match.update!(accepted_at: 1.hour.ago, finished_at: 1.hour.ago, reviewed_at: 1.hour.ago,
                             winner_side: 1, set1_side1_score: 6, set1_side2_score: 3) }

      it "Does not permit" do
        expect(subject).not_to permit(player, match)
      end
    end

    context "When player is not assigned to the match" do
      before do
        match.assignments = [
          build(:assignment, player: create(:player, seasons: [season]), side: 1),
          build(:assignment, player: create(:player, seasons: [season]), side: 2)
        ]
      end

      it "Does not permit" do
        expect(subject).not_to permit(player, match)
      end
    end
  end
end
