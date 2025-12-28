require 'rails_helper'

RSpec.describe Match, type: :model do
  let!(:season) { create(:season) }

  describe "Validations" do

    describe "existing_matches" do
      subject { build(:match,
                      competitable: season,
                      requested_at: Time.now,
                      accepted_at: nil,
                      rejected_at: nil,
                      finished_at: nil,
                      assignments: [
                        build(:assignment, side: 1, player: player1),
                        build(:assignment, side: 2, player: player2)
                      ]) }

      let!(:player1) { create(:player, seasons: [season]) }
      let!(:player2) { create(:player, seasons: [season]) }

      context "When other single, unfinished, unaccepted, unrejected match exists" do
        let!(:other_match) { create(:match,
                                    competitable: competitable,
                                    requested_at: Time.now,
                                    accepted_at: nil,
                                    rejected_at: nil,
                                    finished_at: nil,
                                    assignments: [
                                      build(:assignment, side: 1, player: player2),
                                      build(:assignment, side: 2, player: player1)
                                    ]) }

        context "In the same season" do
          let!(:competitable) { season }

          it "Is not valid" do
            expect(subject).not_to be_valid
          end
        end

        context "In another season" do
          let!(:competitable) { create(:season,
                                       name: "#{Date.today.year - 1}",
                                       ended_at: 1.year.ago,
                                       players: [player1, player2]) }

          it "Is valid" do
            expect(subject).to be_valid
          end

        end

        context "In the tournament of the same season" do
          let!(:competitable) { create(:tournament, season: season) }

          it "Is valid" do
            expect(subject).to be_valid
          end
        end
      end

      context "When other single rejected unfinished match exists in the same season" do
        let!(:other_match) { create(:match,
                                    competitable: season,
                                    requested_at: Time.now,
                                    accepted_at: nil,
                                    rejected_at: Time.now,
                                    finished_at: nil,
                                    assignments: [
                                      build(:assignment, side: 1, player: player2),
                                      build(:assignment, side: 2, player: player1)
                                    ]) }

        it "Is valid" do
          expect(subject).to be_valid
        end

      end

      context "When other single finished match exists in the same season" do
        let!(:other_match) { create(:match,
                                    competitable: season,
                                    requested_at: Time.now,
                                    accepted_at: Time.now,
                                    rejected_at: nil,
                                    finished_at: Time.now,
                                    winner_side: 1,
                                    set1_side1_score: 6,
                                    set1_side2_score: 4,
                                    assignments: [
                                      build(:assignment, side: 1, player: player2),
                                      build(:assignment, side: 2, player: player1)
                                    ]) }

        it "Is valid" do
          expect(subject).to be_valid
        end

      end

      context "When other double, unfinished, unaccepted, unrejected match exists" do
        let!(:player3) { create(:player, seasons: [season]) }
        let!(:player4) { create(:player, seasons: [season]) }
        let!(:other_match) { create(:match,
                                    competitable: season,
                                    requested_at: Time.now,
                                    accepted_at: nil,
                                    rejected_at: nil,
                                    finished_at: nil,
                                    assignments: [
                                      build(:assignment, side: 1, player: player4),
                                      build(:assignment, side: 1, player: player3),
                                      build(:assignment, side: 2, player: player2),
                                      build(:assignment, side: 2, player: player1)
                                    ]) }

        it "Is valid" do
          expect(subject).to be_valid
        end
      end
    end


    describe "Validators" do
      it "is validated with PendingChallengeValidator" do
        expect_any_instance_of(PendingChallengeValidator).to receive(:validate).with(kind_of(Match))
        build(:match).valid?
      end

      it "is validated with PlayerAssignmentsValidator" do
        expect_any_instance_of(PlayerAssignmentsValidator).to receive(:validate).with(kind_of(Match))
        build(:match).valid?
      end
    end


    describe "player_assignments" do
      subject { build(:match,
                      competitable: competitable,
                      requested_at: Time.now,
                      accepted_at: nil,
                      rejected_at: nil,
                      finished_at: nil,
                      assignments: assignments) }

      let!(:player1) { create(:player) }
      let!(:player2) { create(:player) }

      context "When match doesn't belong to a tournament" do
        let!(:competitable) { season }

        context "When all players are enrolled to the season" do
          before do
            season.players << player1
            season.players << player2
          end

          context "When number of assignments is correct" do
            let(:assignments) do
              [
                build(:assignment, side: 1, player: player1),
                build(:assignment, side: 2, player: player2)
              ]
            end

            it "Is valid" do
              expect(subject).to be_valid
            end
          end

          context "When number of assignments is not correct" do
            let(:assignments) do
              [
                build(:assignment, side: 2, player: player2)
              ]
            end

            it "Is not valid" do
              expect(subject).not_to be_valid
            end
          end

        end

        context "When assigned player is not enrolled to the season" do
          before do
            season.players << player1
          end

          let(:assignments) do
            [
              build(:assignment, side: 1, player: player1),
              build(:assignment, side: 2, player: player2)
            ]
          end

          it "Is not valid" do
            expect(subject).not_to be_valid
          end
        end
      end

      context "When match belongs to a tournament and players are not enrolled to the season" do
        let!(:competitable) { create(:tournament, season: season) }

        context "When number of assignments is correct" do
          let(:assignments) do
            [
              build(:assignment, side: 1, player: player1),
              build(:assignment, side: 2, player: player2)
            ]
          end

          it "Is valid" do
            expect(subject).to be_valid
          end

        end

        context "When number of assignments is not correct" do
          let(:assignments) do
            [
              build(:assignment, side: 2, player: player1)
            ]
          end

          it "Is not valid" do
            expect(subject).not_to be_valid
          end
        end
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
          create(:match, competitable: season, kind: 'single',
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
          create(:match, competitable: season, kind: 'double',
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
  end
end
