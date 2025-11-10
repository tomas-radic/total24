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

    describe "finish" do

      subject { match.finish attributes }

      let!(:match) { create(:match,
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
      let!(:place) { create(:place) }
      let(:play_date) { Date.yesterday }
      let(:notes) { "Great match." }


      context "With accepted match" do
        before { match.update_column(:accepted_at, Time.now) }

        context "Match has not been retired" do
          let(:attributes) do
            {
              "score" => "641663",
              "score_side" => 2,
              "retired_player_id" => "",
              "play_date" => play_date.to_s,
              "place_id" => place.id,
              "notes" => notes
            }
          end

          it "Correctly finishes and returns the match" do
            result = subject

            result.reload
            expect(result).to be_a(Match)
            expect(result).to have_attributes(
                                set1_side1_score: 4,
                                set1_side2_score: 6,
                                set2_side1_score: 6,
                                set2_side2_score: 1,
                                set3_side1_score: 3,
                                set3_side2_score: 6,
                                winner_side: 2,
                                play_date: play_date,
                                notes: notes
                              )

            expect(result.finished_at).not_to be_nil
            expect(result.reviewed_at).not_to be_nil
            expect(result.assignments.find { |a| a.is_retired? }).to be_nil
          end
        end

        context "Match has been retired" do
          let(:attributes) do
            {
              "score" => "641653",
              "score_side" => 1,
              "retired_player_id" => player1.id,
              "play_date" => play_date.to_s,
              "place_id" => place.id,
              "notes" => notes
            }
          end

          it "Correctly finishes and returns the match" do
            result = subject

            result.reload
            expect(result).to be_a(Match)
            expect(result).to have_attributes(
                                set1_side1_score: 6,
                                set1_side2_score: 4,
                                set2_side1_score: 1,
                                set2_side2_score: 6,
                                set3_side1_score: 5,
                                set3_side2_score: 3,
                                winner_side: 2,
                                play_date: play_date,
                                notes: notes
                              )

            expect(result.finished_at).not_to be_nil
            expect(result.reviewed_at).not_to be_nil
            expect(result.assignments.find { |a| a.is_retired? }.player_id).to eq(player1.id)
          end
        end

        xcontext "With match finished less than 5 minutes ago" do
          let(:finish_time) { 1.minute.ago }

          before do
            match.update_columns(
              finished_at: finish_time,
              reviewed_at: finish_time,
              accepted_at: 1.hour.ago,
              set1_side1_score: 3,
              set1_side2_score: 6,
              winner_side: 2
            )
          end

          let(:attributes) do
            {
              "score" => "63",
              "score_side" => 1,
              "retired_player_id" => "",
              "play_date" => play_date.to_s,
              "place_id" => place.id,
              "notes" => "New note."
            }
          end

          it "Re-finishes the match" do
            result = subject

            result.reload
            expect(result).to be_a(Match)
            expect(result).to have_attributes(
                                set1_side1_score: 6,
                                set1_side2_score: 3,
                                set2_side1_score: nil,
                                set2_side2_score: nil,
                                set3_side1_score: nil,
                                set3_side2_score: nil,
                                winner_side: 1,
                                finished_at: finish_time,
                                reviewed_at: finish_time,
                                play_date: play_date,
                                notes: "New note."
                              )

            expect(result.finished_at).not_to be_nil
            expect(result.reviewed_at).not_to be_nil
            expect(result.assignments.find { |a| a.is_retired? }).to be_nil
          end
        end

        xcontext "With match finished more than 5 minutes ago" do
          let(:finish_time) { 10.minutes.ago }

          before do
            match.update_columns(
              finished_at: finish_time,
              reviewed_at: finish_time,
              accepted_at: 1.hour.ago,
              set1_side1_score: 3,
              set1_side2_score: 6,
              winner_side: 2,
              play_date: play_date,
              notes: notes
            )
          end

          let(:attributes) do
            {
              "score" => "63",
              "score_side" => 1,
              "retired_player_id" => "",
              "play_date" => play_date.to_s,
              "place_id" => place.id,
              "notes" => "New note."
            }
          end

          it "Stores the error and does not re-finish the match" do
            result = subject

            result.reload
            expect(result).to be_a(Match)
            expect(result).to have_attributes(
                                set1_side1_score: 3,
                                set1_side2_score: 6,
                                set2_side1_score: nil,
                                set2_side2_score: nil,
                                set3_side1_score: nil,
                                set3_side2_score: nil,
                                finished_at: finish_time,
                                reviewed_at: finish_time,
                                winner_side: 2,
                                play_date: play_date,
                                notes: notes
                              )

            expect(result.errors[:finished_at].first).to eq("Výsledok zápasu už bol zapísaný.")
          end
        end

        context "With reviewed match" do
          skip "Currently matches are 'auto-reviewed', make sure to deny re-finishing matches if this changes."
        end

        context "With incorrect score attribute" do
          let(:attributes) do
            {
              "score" => "64165 ",
              "score_side" => 1,
              "retired_player_id" => "",
              "play_date" => play_date.to_s,
              "place_id" => place.id,
              "notes" => notes
            }
          end

          it "Stores the error and does not finish the match" do
            result = subject

            result.reload
            expect(result).to be_a(Match)
            expect(result).to have_attributes(
                                set1_side1_score: nil,
                                set1_side2_score: nil,
                                set2_side1_score: nil,
                                set2_side2_score: nil,
                                set3_side1_score: nil,
                                set3_side2_score: nil,
                                finished_at: nil,
                                reviewed_at: nil,
                                winner_side: nil,
                                play_date: nil,
                                notes: nil
                              )

            expect(result.errors[:score].first).to eq("Neplatný výsledok zápasu.")
          end
        end

        xcontext "When season is ended" do
          before do
            season.update_column(:ended_at, Time.now)
          end

          let(:attributes) do
            {
              "score" => "64",
              "score_side" => 1,
              "retired_player_id" => "",
              "play_date" => play_date.to_s,
              "place_id" => place.id,
              "notes" => notes
            }
          end

          it "Stores the error and does not finish the match" do
            result = subject

            result.reload
            expect(result).to be_a(Match)
            expect(result).to have_attributes(
                                set1_side1_score: nil,
                                set1_side2_score: nil,
                                set2_side1_score: nil,
                                set2_side2_score: nil,
                                set3_side1_score: nil,
                                set3_side2_score: nil,
                                finished_at: nil,
                                reviewed_at: nil,
                                winner_side: nil,
                                play_date: nil,
                                notes: nil
                              )

            expect(result.errors[:season].first).to eq("Sezóna je už skončená.")
          end
        end
      end

      xcontext "With unaccepted match" do
        let(:attributes) do
          {
            "score" => "64",
            "score_side" => 1,
            "retired_player_id" => "",
            "play_date" => play_date.to_s,
            "place_id" => place.id,
            "notes" => notes
          }
        end

        it "Stores the error and does not finish the match" do
          result = subject

          result.reload
          expect(result).to be_a(Match)
          expect(result).to have_attributes(
                              set1_side1_score: nil,
                              set1_side2_score: nil,
                              set2_side1_score: nil,
                              set2_side2_score: nil,
                              set3_side1_score: nil,
                              set3_side2_score: nil,
                              finished_at: nil,
                              reviewed_at: nil,
                              winner_side: nil,
                              play_date: nil,
                              notes: nil
                            )

          expect(result.errors[:status].first).to eq("Zápas nie je akceptovaný súperom.")
        end
      end
    end

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

  describe "Class methods" do

    describe "singles_with_players" do
      subject { described_class.singles_with_players(player1, player2, competitable:) }

      let!(:season) { create(:season, name: 'season') }
      let!(:another_season) { create(:season, name: 'another season', ended_at: 1.year.ago) }
      let!(:tournament) { create(:tournament, name: 'tournament', season:) }
      let!(:player1) { create(:player, name: 'player1', seasons: [season, another_season]) }
      let!(:player2) { create(:player, name: 'player2', seasons: [season, another_season]) }
      let!(:player3) { create(:player, name: 'player3', seasons: [season, another_season]) }
      let!(:player4) { create(:player, name: 'player4', seasons: [season, another_season]) }

      let!(:season_matching_match1) { create(:match, competitable: season,
                                             assignments: [
                                               build(:assignment, side: 1, player: player1),
                                               build(:assignment, side: 2, player: player2)
                                             ]) }
      let!(:season_matching_match2) { create(:match, :finished, competitable: season, kind: 'single',
                                             assignments: [
                                               build(:assignment, side: 1, player: player2),
                                               build(:assignment, side: 2, player: player1)
                                             ]) }
      let!(:season_unmatching_match1) { create(:match, competitable: season, kind: 'single',
                                             assignments: [
                                               build(:assignment, side: 1, player: player1),
                                               build(:assignment, side: 2, player: player3)
                                             ]) }
      let!(:season_unmatching_match2) { create(:match, competitable: season, kind: 'single',
                                             assignments: [
                                               build(:assignment, side: 1, player: player3),
                                               build(:assignment, side: 2, player: player2)
                                             ]) }
      let!(:another_season_matching_match1) { create(:match, competitable: another_season, kind: 'single',
                                               assignments: [
                                                 build(:assignment, side: 1, player: player1),
                                                 build(:assignment, side: 2, player: player2)
                                               ]) }
      let!(:season_unmatching_match4) { create(:match, competitable: season, kind: 'double',
                                               assignments: [
                                                 build(:assignment, side: 1, player: player1),
                                                 build(:assignment, side: 1, player: player3),
                                                 build(:assignment, side: 2, player: player2),
                                                 build(:assignment, side: 2, player: player4)
                                               ]) }
      let!(:tournament_matching_match1) { create(:match, competitable: tournament, kind: 'single',
                                             assignments: [
                                               build(:assignment, side: 1, player: player1),
                                               build(:assignment, side: 2, player: player2)
                                             ]) }

      let!(:tournament_unmatching_match1) { create(:match, competitable: tournament, kind: 'single',
                                                 assignments: [
                                                   build(:assignment, side: 1, player: player3),
                                                   build(:assignment, side: 2, player: player2)
                                                 ]) }

      context "With season as competitable" do
        let(:competitable) { season }

        it "Returns matching matches" do
          result = subject

          expect(result.count).to eq(2)
          expect(result.pluck(:id).sort).to eq([season_matching_match1.id, season_matching_match2.id].sort)
        end
      end

      context "With tournament as competitable" do
        let(:competitable) { tournament }

        it "Returns matching matches" do
          result = subject

          expect(result.pluck(:id)).to eq([tournament_matching_match1.id])
        end
      end

      context "Without specifying a competitable" do
        let(:competitable) { nil }

        it "Returns matching matches" do
          result = subject

          expect(result.count).to eq(4)
          expect(result.pluck(:id).sort).to eq([season_matching_match1.id, season_matching_match2.id,
                                                another_season_matching_match1.id, tournament_matching_match1.id].sort)
        end
      end

    end
  end
end
