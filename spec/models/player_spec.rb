require 'rails_helper'

RSpec.describe Player, type: :model do
  let!(:player) { create(:player) }
  let!(:season) { create(:season) }


  describe "Instance methods" do

    describe "display_name" do
      subject { player.display_name(privacy:) }

      let!(:player) { create(:player, name: "Roger Federer jr") }

      context "When privacy is false" do
        let(:privacy) { false }

        it "Returns whole player name" do
          expect(subject).to eq(player.name)
        end
      end

      context "When privacy is true" do
        let(:privacy) { true }

        it "Returns private player name" do
          expect(subject).to eq("Roger F. j.")
        end
      end
    end

    describe "season_matches" do

      subject { player.season_matches(season) }

      it "TODO"

    end


    # opponents method is not used, to be removed from project
    xdescribe "opponents" do
      subject { player.opponents(season: season, pending: pending, ranking_counted: ranking_counted) }

      before do
        season.players << player
        another_season.players << player
      end

      let!(:match1) do
        create(:match, :requested, competitable: season,
               assignments: [
                 build(:assignment, side: 1, player: create(:player, name: "P111", seasons: [season])),
                 build(:assignment, side: 2, player: player)
               ])
      end

      let!(:match2) do
        create(:match, :accepted, competitable: season,
               assignments: [
                 build(:assignment, side: 1, player: player),
                 build(:assignment, side: 2, player: create(:player, name: "P221", seasons: [season]))
               ])
      end

      let!(:match3) do
        create(:match, :rejected, competitable: season,
               assignments: [
                 build(:assignment, side: 1, player: create(:player, name: "P311", seasons: [season])),
                 build(:assignment, side: 2, player: player)
               ])
      end

      let!(:match4) do
        create(:match, :finished, competitable: season,
               assignments: [
                 build(:assignment, side: 1, player: create(:player, name: "P411", seasons: [season])),
                 build(:assignment, side: 2, player: player)
               ])
      end

      let!(:match5) do
        create(:match, :reviewed, competitable: season,
               assignments: [
                 build(:assignment, side: 1, player: player),
                 build(:assignment, side: 2, player: create(:player, name: "P521", seasons: [season]))
               ])
      end

      let!(:match6) do
        create(:match, :reviewed, published_at: nil, competitable: season,
               assignments: [
                 build(:assignment, side: 1, player: player),
                 build(:assignment, side: 2, player: create(:player, name: "P621", seasons: [season]))
               ])
      end

      let!(:match7) do
        create(:match, competitable: create(:tournament, season: season), ranking_counted: false,
               assignments: [
                 build(:assignment, side: 1, player: create(:player, name: "P711", seasons: [season])),
                 build(:assignment, side: 2, player: player)
               ])
      end

      let!(:match8) do
        create(:match, competitable: create(:tournament, season: season), ranking_counted: false,
               assignments: [
                 build(:assignment, side: 1, player: create(:player, name: "P811", seasons: [season])),
                 build(:assignment, side: 1, player: create(:player, name: "P812", seasons: [season])),
                 build(:assignment, side: 2, player: player),
                 build(:assignment, side: 2, player: create(:player, name: "P822", seasons: [season]))
               ])
      end

      let!(:match9) do
        create(:match, competitable: season,
               assignments: [
                 build(:assignment, side: 1, player: create(:player, name: "P911", seasons: [season])),
                 build(:assignment, side: 2, player: player)
               ])
      end

      let!(:match10) do
        create(:match, competitable: season,
               assignments: [
                 build(:assignment, side: 1, player: create(:player, name: "P1011", seasons: [season])),
                 build(:assignment, side: 2, player: create(:player, name: "P1021", seasons: [season]))
               ])
      end

      let!(:another_season) { create(:season, name: Date.today.year - 1, ended_at: 6.months.ago) }
      let!(:match11) do
        create(:match, :accepted, competitable: another_season,
               assignments: [
                 build(:assignment, side: 1, player: player),
                 build(:assignment, side: 2, player: create(:player, name: "P1121", seasons: [another_season]))
               ])
      end

      let!(:match12) do
        create(:match, competitable: create(:tournament, season: another_season), ranking_counted: false,
               assignments: [
                 build(:assignment, side: 1, player: create(:player, name: "P1211", seasons: [season])),
                 build(:assignment, side: 2, player: player)
               ])
      end


      context "With parameters: pending true, ranking_counted true" do
        let(:pending) { true }
        let(:ranking_counted) { true }

        it "Returns player's opponents" do
          result = subject

          expect(result.map(&:name)).to include(
                                          "P111",
                                          "P221",
                                          "P911"
                                        )
        end
      end

      context "With parameters: pending false, ranking_counted true" do
        let(:pending) { false }
        let(:ranking_counted) { true }

        it "Returns player's opponents" do
          result = subject

          expect(result.map(&:name)).to include(
                                          "P111",
                                          "P221",
                                          "P411",
                                          "P521",
                                          "P911"
                                        )
        end
      end

      context "With parameters: pending true, ranking_counted false" do
        let(:pending) { true }
        let(:ranking_counted) { false }

        it "Returns player's opponents" do
          result = subject

          expect(result.map(&:name)).to include(
                                          "P111",
                                          "P221",
                                          "P711",
                                          "P811",
                                          "P812",
                                          "P822",
                                          "P911"
                                        )
        end
      end

      context "With parameters: pending false, ranking_counted false" do
        let(:pending) { false }
        let(:ranking_counted) { false }

        it "Returns player's opponents" do
          result = subject

          expect(result.map(&:name)).to include(
                                          "P111",
                                          "P221",
                                          "P411",
                                          "P711",
                                          "P811",
                                          "P812",
                                          "P822",
                                          "P911"
                                        )
        end
      end

      context "Without season, pending and ranking_counted parameters" do
        subject { player.opponents }

        let(:pending) { false }
        let(:ranking_counted) { false }

        it "Returns player's opponents" do
          result = subject

          expect(result.map(&:name)).to include(
                                          "P111",
                                          "P221",
                                          "P411",
                                          "P711",
                                          "P811",
                                          "P812",
                                          "P822",
                                          "P911",
                                          "P1121",
                                          "P1211"
                                        )
        end
      end
    end


    describe "anonymize!" do
      subject { player.anonymize! }

      before do
        season.players << player << another_player
        player.update!(email: email, name: name, phone_nr: phone_nr, birth_year: birth_year)
      end

      let(:email) { "player@somewhere.com" }
      let(:name) { "Some Player" }
      let(:phone_nr) { "123456" }
      let(:birth_year) { Date.today.year }
      let!(:another_player) { create(:player, name: 'another player') }
      let!(:finished_match) do
        create(:match, :finished, competitable: season,
               assignments: [
                 build(:assignment, side: 1, player: player),
                 build(:assignment, side: 2, player: another_player)
               ])
      end

      let!(:unfinished_match) do
        create(:match, :requested, competitable: season,
               assignments: [
                 build(:assignment, side: 2, player: player),
                 build(:assignment, side: 1, player: another_player)
               ])
      end

      it "Anonymizes player and destroys their unfinished matches" do
        unfinished_match_id = unfinished_match.id
        result = subject

        result.reload
        expect(result.anonymized_at).not_to be_nil
        expect(result.email).not_to eq(email)
        expect(result.name).to eq("(zmazaný hráč)")
        expect(result.phone_nr).to be_nil
        expect(result.birth_year).to be_nil
        expect(Match.find_by(id: finished_match.id)).not_to be_nil
        expect(Match.find_by(id: unfinished_match_id)).to be_nil
      end
    end
  end
end
