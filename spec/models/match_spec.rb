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


    describe "result_state" do
      subject { build(:match,
                      competitable: season,
                      requested_at: Time.now,
                      accepted_at: Time.now,
                      rejected_at: nil,
                      finished_at: Time.now,
                      winner_side: 2,
                      assignments: [
                        build(:assignment, side: 1, player: player1),
                        build(:assignment, side: 2, player: player2)
                      ]) }

      let!(:player1) { create(:player, seasons: [season]) }
      let!(:player2) { create(:player, seasons: [season]) }


      context "When none of the players retired the match" do

        context "With sets score 1:2" do
          before do
            subject.set1_side1_score = 6
            subject.set1_side2_score = 3
            subject.set2_side1_score = 4
            subject.set2_side2_score = 6
            subject.set3_side1_score = 1
            subject.set3_side2_score = 6
          end

          it "Is valid" do
            expect(subject).to be_valid
          end
        end

        context "With sets score 1:1" do
          before do
            subject.set1_side1_score = 6
            subject.set1_side2_score = 3
            subject.set2_side1_score = 4
            subject.set2_side2_score = 6
          end

          it "Is not valid" do
            expect(subject).not_to be_valid
          end
        end
      end

      context "When any of the players retired the match" do

        before do
          subject.assignments.sample.tap do |a|
            a.is_retired = true
          end
        end

        context "With sets score 1:2" do
          before do
            subject.set1_side1_score = 6
            subject.set1_side2_score = 3
            subject.set2_side1_score = 4
            subject.set2_side2_score = 6
            subject.set3_side1_score = 1
            subject.set3_side2_score = 6
          end

          it "Is valid" do
            expect(subject).to be_valid
          end
        end

        context "With sets score 1:1" do
          before do
            subject.set1_side1_score = 6
            subject.set1_side2_score = 3
            subject.set2_side1_score = 4
            subject.set2_side2_score = 6
          end

          it "Is valid" do
            expect(subject).to be_valid
          end
        end
      end
    end

  end


  describe "Instance methods" do

    describe "interested_players" do
      subject { match.interested_players }

      # region Data
      let!(:season) { create(:season, name: 'season') }
      let!(:player1) { create(:player, name: 'Player1', seasons: [season]) }
      let!(:player2) { create(:player, name: 'Player2', seasons: [season]) }
      let!(:match) { create(:match, competitable: season, kind: 'single',
                            assignments: [
                              build(:assignment, side: 1, player: player1),
                              build(:assignment, side: 2, player: player2)]) }

      # Player3
      #   added a comment to the match
      let!(:player3) { create(:player, name: 'Player3',
                              comments: [build(:comment, commentable: match, content: 'Comment1 of Player3')]) }

      # Player4
      #   added a like to the match
      let!(:player4) { create(:player, name: 'Player4',
                              reactions: [build(:reaction, reactionable: match)]) }

      # Player5
      #   added a like and a comment to the match
      let!(:player5) { create(:player, name: 'Player5',
                              reactions: [build(:reaction, reactionable: match)],
                              comments: [build(:comment, commentable: match, content: 'Comment1 of Player5')]) }

      # Player6
      #   added and deleted a comment to the match
      let!(:player6) { create(:player, name: 'Player6',
                              comments: [build(:comment, commentable: match, content: 'Comment1 of Player6', deleted_at: 1.hour.ago)]) }
      # endregion Data

      it "Returns the players of the match and players who have commented on the match" do
        result = subject

        expect(result.size).to eq(5)
        expect(result).to include(player1, player2, player3, player5, player6)
      end
    end

    describe "notification_recipients_for" do
      subject { match.notification_recipients_for(notifier_class) }

      # region Data
      let(:notifier_class) { MatchUpdatedNotifier }
      let!(:season) { create(:season, name: 'season') }
      let!(:player1) { create(:player, name: 'Player1', seasons: [season]) }
      let!(:player2) { create(:player, name: 'Player2', seasons: [season]) }

      let!(:enrollment_of_player3) { create(:enrollment, player: player3, season: season) }

      let!(:match) { create(:match, competitable: season, kind: 'single',
                            assignments: [
                              build(:assignment, side: 1, player: player1),
                              build(:assignment, side: 2, player: player2)]) }

      let!(:player3) { create(:player, name: 'Player3') }
      let!(:player4) { create(:player, name: 'Player4') }
      let!(:player5) { create(:player, name: 'Player5') }
      let!(:player6) { create(:player, name: 'Player6') }

      let!(:another_match) { create(:match, competitable: season, kind: 'single',
                                    assignments: [
                                      build(:assignment, side: 1, player: player1),
                                      build(:assignment, side: 2, player: player3)]) }
      # endregion Data

      before do
        # Player1 has a notification which is seen and read
        Noticed::Notification.create!(
          type: "#{notifier_class}::Notification", recipient: player1, seen_at: 1.hour.ago, read_at: 1.hour.ago,
          event: Noticed::Event.new(type: "#{notifier_class}", record: match)
        )

        # Player3 has a notification which is seen but unread
        Noticed::Notification.create!(
          type: "#{notifier_class}::Notification", recipient: player3, seen_at: 1.hour.ago, read_at: nil,
          event: Noticed::Event.new(type: "#{notifier_class}", record: match)
        )

        # Player4 has a notification which is unseen and unread (should be excluded)
        Noticed::Notification.create!(
          type: "#{notifier_class}::Notification", recipient: player4, seen_at: nil, read_at: nil,
          event: Noticed::Event.new(type: "#{notifier_class}", record: match)
        )

        # Player5 has another type of notification which is unseen and unread
        Noticed::Notification.create!(
          type: "NewMatchNotifier::Notification", recipient: player5, seen_at: nil, read_at: nil,
          event: Noticed::Event.new(type: "NewMatchNotifier", record: match)
        )

        # Player6 has seen and read notification for another match
        Noticed::Notification.create!(
          type: "#{notifier_class}::Notification", recipient: player6, seen_at: 1.hour.ago, read_at: nil,
          event: Noticed::Event.new(type: "#{notifier_class}", record: another_match)
        )
      end

      it "Returns the players who do not have unseen notification of given type for this match" do
        expect(match).to receive(:interested_players).and_return(Player.all)

        result = subject

        expect(result.size).to eq(5)
        expect(result).to include(player1, player2, player3, player5, player6)
      end
    end
  end
end
