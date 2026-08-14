require 'rails_helper'

RSpec.describe Match, type: :model do
  let!(:season) { create(:season) }

  describe "Validations" do
    describe "Validators used" do
      it "is validated with PendingChallengeValidator" do
        expect_any_instance_of(PendingChallengeValidator).to receive(:validate).with(kind_of(Match))
        build(:match).valid?
      end

      it "is validated with PlayerAssignmentsValidator" do
        expect_any_instance_of(PlayerAssignmentsValidator).to receive(:validate).with(kind_of(Match))
        build(:match).valid?
      end
    end
  end


  describe "Instance methods" do
    describe "#opponents_of" do
      let!(:player1) { create(:player, seasons: [season]) }
      let!(:player2) { create(:player, seasons: [season]) }
      let!(:player3) { create(:player, seasons: [season]) }
      let!(:player4) { create(:player, seasons: [season]) }
      let!(:outsider) { create(:player, seasons: [season]) }

      context "in a single match" do
        let!(:match) do
          create(:match, season: season, kind: 'single',
                 assignments: [
                   build(:assignment, side: 1, player: player1),
                   build(:assignment, side: 2, player: player2)
                 ])
        end

        it "returns the opponent for player 1" do
          expect(match.opponents_of(player1)).to contain_exactly(player2)
        end

        it "returns the opponent for player 2" do
          expect(match.opponents_of(player2)).to contain_exactly(player1)
        end

        it "returns nil for an outsider" do
          expect(match.opponents_of(outsider)).to be_nil
        end
      end

      context "in a double match" do
        let!(:match) do
          create(:match, season: season, kind: 'double',
                 assignments: [
                   build(:assignment, side: 1, player: player1),
                   build(:assignment, side: 1, player: player2),
                   build(:assignment, side: 2, player: player3),
                   build(:assignment, side: 2, player: player4)
                 ])
        end

        it "returns both opponents for player 1" do
          expect(match.opponents_of(player1)).to contain_exactly(player3, player4)
        end

        it "returns both opponents for player 3" do
          expect(match.opponents_of(player3)).to contain_exactly(player1, player2)
        end

        it "returns nil for an outsider" do
          expect(match.opponents_of(outsider)).to be_nil
        end
      end
    end

    describe "#flip_result!" do
      subject { match.flip_result! }

      context "With finished match" do
        let!(:match) { create(:match, :finished, season:, winner_side: 1,
                              set1_side1_score: 6, set1_side2_score: 4, set2_side1_score: 6, set2_side2_score: 1) }

        it "Flips the match result" do
          subject

          match.reload
          expect(match.winner_side).to eq(2)
          expect(match.set1_side1_score).to eq(4)
          expect(match.set1_side2_score).to eq(6)
          expect(match.set2_side1_score).to eq(1)
          expect(match.set2_side2_score).to eq(6)
        end
      end

      context "With unfinished match" do
        let!(:match) { create(:match, :accepted, season:) }

        it "Raises error" do
          expect { subject }.to raise_error(StandardError, "Match is not finished")
        end
      end
    end
  end
end
