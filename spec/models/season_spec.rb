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


    describe "play_offs" do
      subject { season.play_offs }

      let!(:season) { create(:season) }

      before do
        ENV['PERFORMANCE_PLAYER_TAG_LABEL'] > 'perf'
        ENV['PERFORMANCE_PLAY_OFF_SIZE'] = '2'
        ENV['REGULAR_A_PLAY_OFF_SIZE'] = '2'
        ENV['REGULAR_B_PLAY_OFF_SIZE'] = '4'

        expect_any_instance_of(Season).to(receive(:ranking).and_return(ranking))
      end

      context "With enough players for each category" do
        let(:ranking) do
          [
            double('perf1', id: 'perf1', played_matches: 5, tags: [double('tag', label: ENV['PERFORMANCE_PLAYER_TAG_LABEL'])]),
            double('perf2', id: 'perf2', played_matches: 6, tags: [double('tag', label: ENV['PERFORMANCE_PLAYER_TAG_LABEL'])]),
            double('reg1', id: 'reg1', played_matches: 8, tags: []),
            double('reg2', id: 'reg2', played_matches: 5, tags: []),
            double('perf3', id: 'perf3', played_matches: 7, tags: [double('tag', label: ENV['PERFORMANCE_PLAYER_TAG_LABEL'])]),
            double('perf4', id: 'perf4', played_matches: 8, tags: [double('tag', label: ENV['PERFORMANCE_PLAYER_TAG_LABEL'])]),
            double('reg3', id: 'reg3', played_matches: 8, tags: []),
            double('reg4', id: 'reg4', played_matches: 5, tags: []),
            double('reg5', id: 'reg5', played_matches: 9, tags: []),
            double('perf5', id: 'perf5', played_matches: 5, tags: [double('tag', label: ENV['PERFORMANCE_PLAYER_TAG_LABEL'])]),
            double('reg6', id: 'reg6', played_matches: 8, tags: []),
            double('reg7', id: 'reg7', played_matches: 9, tags: []),
            double('reg8', id: 'reg8', played_matches: 4, tags: []),
            double('reg9', id: 'reg9', played_matches: 9, tags: []),
            double('reg10', id: 'reg10', played_matches: 9, tags: []),
            double('reg11', id: 'reg11', played_matches: 9, tags: [])
          ]
        end

        context "With minimum played matches count" do
          before do
            ENV['PLAY_OFF_MIN_MATCHES_COUNT'] = '6'
          end

          it "Returns players matching play off conditions" do
            perf_playoff, reg_a_playoff, reg_b_playoff = subject

            expect(perf_playoff.length).to eq(2)
            expect(perf_playoff[0].id).to eq('perf2')
            expect(perf_playoff[1].id).to eq('perf3')

            expect(reg_a_playoff.length).to eq(2)
            expect(reg_a_playoff[0].id).to eq('reg1')
            expect(reg_a_playoff[1].id).to eq('reg3')

            expect(reg_b_playoff.length).to eq(4)
            expect(reg_b_playoff[0].id).to eq('reg5')
            expect(reg_b_playoff[1].id).to eq('reg6')
            expect(reg_b_playoff[2].id).to eq('reg7')
            expect(reg_b_playoff[3].id).to eq('reg9')
          end
        end

        context "Without minimum played matches count" do
          before do
            ENV['PLAY_OFF_MIN_MATCHES_COUNT'] = nil
          end

          it "Returns players matching play off conditions" do
            perf_playoff, reg_a_playoff, reg_b_playoff = subject

            expect(perf_playoff.length).to eq(2)
            expect(perf_playoff[0].id).to eq('perf1')
            expect(perf_playoff[1].id).to eq('perf2')

            expect(reg_a_playoff.length).to eq(2)
            expect(reg_a_playoff[0].id).to eq('reg1')
            expect(reg_a_playoff[1].id).to eq('reg2')

            expect(reg_b_playoff.length).to eq(4)
            expect(reg_b_playoff[0].id).to eq('reg3')
            expect(reg_b_playoff[1].id).to eq('reg4')
            expect(reg_b_playoff[2].id).to eq('reg5')
            expect(reg_b_playoff[3].id).to eq('reg6')
          end
        end
      end

      context "When not enough players for categories" do
        let(:ranking) do
          [
            double('perf1', id: 'perf1', played_matches: 5, tags: [double('tag', label: ENV['PERFORMANCE_PLAYER_TAG_LABEL'])]),
            double('perf2', id: 'perf2', played_matches: 6, tags: [double('tag', label: ENV['PERFORMANCE_PLAYER_TAG_LABEL'])]),
            double('reg1', id: 'reg1', played_matches: 8, tags: []),
            double('reg2', id: 'reg2', played_matches: 5, tags: []),
            double('reg3', id: 'reg3', played_matches: 8, tags: []),
            double('reg4', id: 'reg4', played_matches: 5, tags: []),
            double('reg5', id: 'reg5', played_matches: 9, tags: []),
            double('reg6', id: 'reg6', played_matches: 4, tags: [])
          ]
        end

        context "With minimum played matches count" do
          before do
            ENV['PLAY_OFF_MIN_MATCHES_COUNT'] = '6'
          end

          it "Returns players matching play off conditions" do
            perf_playoff, reg_a_playoff, reg_b_playoff = subject

            expect(perf_playoff.length).to eq(1)
            expect(perf_playoff[0].id).to eq('perf2')

            expect(reg_a_playoff.length).to eq(2)
            expect(reg_a_playoff[0].id).to eq('reg1')
            expect(reg_a_playoff[1].id).to eq('reg3')

            expect(reg_b_playoff.length).to eq(1)
            expect(reg_b_playoff[0].id).to eq('reg5')
          end
        end
      end
    end
  end
end
