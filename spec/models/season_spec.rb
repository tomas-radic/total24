require 'rails_helper'

RSpec.describe Season, type: :model do

  describe "Instance methods" do
    describe "ranking" do
      subject { season.ranking }

      let!(:season) { create(:season, name: 'season') }
      let!(:other_season) { create(:season, :ended, name: 'other season') }
      let!(:playerA) { create(:player, name: 'A', enrollments: [build(:enrollment, season:, created_at: 1.days.ago), build(:enrollment, season: other_season)]) }
      let!(:playerB) { create(:player, name: 'B', enrollments: [build(:enrollment, season:, created_at: 2.days.ago)]) }
      let!(:playerC) { create(:player, name: 'C', enrollments: [build(:enrollment, season:, created_at: 3.days.ago, canceled_at: 1.hour.ago)]) }
      let!(:playerD) { create(:player, name: 'D', enrollments: [build(:enrollment, season:, created_at: 4.days.ago), build(:enrollment, season: other_season)]) }
      let!(:playerE) { create(:player, name: 'E', enrollments: [build(:enrollment, season:, created_at: 5.days.ago)]) }
      let!(:playerF) { create(:player, name: 'F', enrollments: [build(:enrollment, season: other_season)]) }
      let!(:match1) { create(:match, :finished, competitable: season, winner_side: 1,
                             assignments: [
                               build(:assignment, side: 1, player: playerA),
                               build(:assignment, side: 2, player: playerB)
                             ]) }
      let!(:match2) { create(:match, :finished, competitable: season, winner_side: 2,
                             assignments: [
                               build(:assignment, side: 1, player: playerC),
                               build(:assignment, side: 2, player: playerA)
                             ]) }
      let!(:match3) { create(:match, :finished, competitable: season, winner_side: 1,
                             assignments: [
                               build(:assignment, side: 1, player: playerB),
                               build(:assignment, side: 2, player: playerC)
                             ]) }
      let!(:match4) { create(:match, :finished, competitable: season, winner_side: 2,
                             assignments: [
                               build(:assignment, side: 1, player: playerD),
                               build(:assignment, side: 2, player: playerA)
                             ]) }
      let!(:match5) { create(:match, :finished, competitable: season, winner_side: 1,
                             assignments: [
                               build(:assignment, side: 1, player: playerD),
                               build(:assignment, side: 2, player: playerB)
                             ]) }
      let!(:unreviewed_match) { create(:match, :finished, competitable: season, winner_side: 2,
                                       assignments: [
                                         build(:assignment, side: 1, player: playerA),
                                         build(:assignment, side: 2, player: playerE)
                                       ]) }
      let!(:other_season_match) { create(:match, :reviewed, competitable: other_season, winner_side: 1,
                                         assignments: [
                                           build(:assignment, side: 1, player: playerA),
                                           build(:assignment, side: 2, player: playerD)
                                         ]) }

      context "Without any reviewed matches" do
        it "Returns correct ranking" do
          result = subject

          expect(result.size).to eq(5)
          expect(result[0]).to have_attributes(id: playerE.id, points: 0, percentage: 0, played_matches: 0, won_matches: 0)
          expect(result[1]).to have_attributes(id: playerD.id, points: 0, percentage: 0, played_matches: 0, won_matches: 0)
          expect(result[2]).to have_attributes(id: playerC.id, points: 0, percentage: 0, played_matches: 0, won_matches: 0)
          expect(result[3]).to have_attributes(id: playerB.id, points: 0, percentage: 0, played_matches: 0, won_matches: 0)
          expect(result[4]).to have_attributes(id: playerA.id, points: 0, percentage: 0, played_matches: 0, won_matches: 0)
        end
      end

      context "With 1st match reviewed" do
        before { match1.update!(reviewed_at: 1.minute.ago) }

        it "Returns correct ranking" do
          result = subject

          expect(result.size).to eq(5)
          expect(result[0]).to have_attributes(id: playerA.id, points: 100, percentage: 100, played_matches: 1, won_matches: 1)
          expect(result[1]).to have_attributes(id: playerB.id, points: 0, percentage: 0, played_matches: 1, won_matches: 0)
          expect(result[2]).to have_attributes(id: playerE.id, points: 0, percentage: 0, played_matches: 0, won_matches: 0)
          expect(result[3]).to have_attributes(id: playerD.id, points: 0, percentage: 0, played_matches: 0, won_matches: 0)
          expect(result[4]).to have_attributes(id: playerC.id, points: 0, percentage: 0, played_matches: 0, won_matches: 0)
        end
      end

      context "With 1st and 2nd match reviewed" do
        before do
          match1.update!(reviewed_at: 1.minute.ago)
          match2.update!(reviewed_at: 1.minute.ago)
        end

        it "Returns correct ranking" do
          result = subject

          expect(result.size).to eq(5)
          expect(result[0]).to have_attributes(id: playerA.id, points: 100, percentage: 100, played_matches: 2, won_matches: 2)
          expect(result[1]).to have_attributes(id: playerC.id, points: 0, percentage: 0, played_matches: 1, won_matches: 0)
          expect(result[2]).to have_attributes(id: playerB.id, points: 0, percentage: 0, played_matches: 1, won_matches: 0)
          expect(result[3]).to have_attributes(id: playerE.id, points: 0, percentage: 0, played_matches: 0, won_matches: 0)
          expect(result[4]).to have_attributes(id: playerD.id, points: 0, percentage: 0, played_matches: 0, won_matches: 0)
        end
      end

      context "With 1st, 2nd and 3rd match reviewed" do
        before do
          match1.update!(reviewed_at: 1.minute.ago)
          match2.update!(reviewed_at: 1.minute.ago)
          match3.update!(reviewed_at: 1.minute.ago)
        end

        it "Returns correct ranking" do
          result = subject

          expect(result.size).to eq(5)
          expect(result[0]).to have_attributes(id: playerA.id, points: 150, percentage: 100, played_matches: 2, won_matches: 2)
          expect(result[1]).to have_attributes(id: playerB.id, points: 50, percentage: 50, played_matches: 2, won_matches: 1)
          expect(result[2]).to have_attributes(id: playerC.id, points: 0, percentage: 0, played_matches: 2, won_matches: 0)
          expect(result[3]).to have_attributes(id: playerE.id, points: 0, percentage: 0, played_matches: 0, won_matches: 0)
          expect(result[4]).to have_attributes(id: playerD.id, points: 0, percentage: 0, played_matches: 0, won_matches: 0)
        end
      end

      context "With 1st, 2nd, 3rd and 4th match reviewed" do
        before do
          match1.update!(reviewed_at: 1.minute.ago)
          match2.update!(reviewed_at: 1.minute.ago)
          match3.update!(reviewed_at: 1.minute.ago)
          match4.update!(reviewed_at: 1.minute.ago)
        end

        it "Returns correct ranking" do
          result = subject

          expect(result.size).to eq(5)
          expect(result[0]).to have_attributes(id: playerA.id, points: 150, percentage: 100, played_matches: 3, won_matches: 3)
          expect(result[1]).to have_attributes(id: playerB.id, points: 50, percentage: 50, played_matches: 2, won_matches: 1)
          expect(result[2]).to have_attributes(id: playerC.id, points: 0, percentage: 0, played_matches: 2, won_matches: 0)
          expect(result[3]).to have_attributes(id: playerD.id, points: 0, percentage: 0, played_matches: 1, won_matches: 0)
          expect(result[4]).to have_attributes(id: playerE.id, points: 0, percentage: 0, played_matches: 0, won_matches: 0)
        end
      end

      context "With 1st, 2nd, 3rd, 4th and 5th match reviewed" do
        before do
          match1.update!(reviewed_at: 1.minute.ago)
          match2.update!(reviewed_at: 1.minute.ago)
          match3.update!(reviewed_at: 1.minute.ago)
          match4.update!(reviewed_at: 1.minute.ago)
          match5.update!(reviewed_at: 1.minute.ago)
        end

        it "Returns correct ranking" do
          result = subject

          expect(result.size).to eq(5)
          expect(result[0]).to have_attributes(id: playerA.id, points: 183, percentage: 100, played_matches: 3, won_matches: 3)
          expect(result[1]).to have_attributes(id: playerD.id, points: 83, percentage: 50, played_matches: 2, won_matches: 1)
          expect(result[2]).to have_attributes(id: playerB.id, points: 33, percentage: 33, played_matches: 3, won_matches: 1)
          expect(result[3]).to have_attributes(id: playerC.id, points: 0, percentage: 0, played_matches: 2, won_matches: 0)
          expect(result[4]).to have_attributes(id: playerE.id, points: 0, percentage: 0, played_matches: 0, won_matches: 0)
        end
      end
    end
  end
end
