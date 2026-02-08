require 'rails_helper'

RSpec.describe Player, type: :model do
  let!(:player) { create(:player) }
  let!(:season) { create(:season) }

  describe "Instance methods" do
    describe "anonymize!" do
      subject { player.anonymize! }

      before do
        create(:enrollment, player: player, season: season)
        create(:enrollment, player: another_player, season: season)
        player.update!(email: email, name: name, phone_nr: phone_nr, birth_year: birth_year)
      end

      let(:email) { "player@somewhere.com" }
      let(:name) { "Some Player" }
      let(:phone_nr) { "123456" }
      let(:birth_year) { Date.today.year }
      let!(:another_player) { create(:player, name: 'another player') }
      let!(:finished_match) do
        create(:match, :finished, season: season,
               assignments: [
                 build(:assignment, side: 1, player: player),
                 build(:assignment, side: 2, player: another_player)
               ])
      end

      let!(:unfinished_match) do
        create(:match, season: season,
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

    describe "assigned_to?" do
      let(:match) { build(:match, assignments: [], season: season) }

      before do
        match.save(validate: false)
      end

      context "when side is not provided" do
        it "returns true if player is assigned to the match" do
          create(:assignment, player: player, match: match, side: 1)
          expect(player.assigned_to?(match)).to be true
        end

        it "returns false if player is not assigned to the match" do
          expect(player.assigned_to?(match)).to be false
        end
      end

      context "when side is provided" do
        it "returns true if player is assigned to the match on the specified side" do
          create(:assignment, player: player, match: match, side: 1)
          expect(player.assigned_to?(match, side: 1)).to be true
        end

        it "returns false if player is assigned to the match on a different side" do
          create(:assignment, player: player, match: match, side: 1)
          expect(player.assigned_to?(match, side: 2)).to be false
        end

        it "returns false if player is not assigned to the match" do
          expect(player.assigned_to?(match, side: 1)).to be false
        end
      end
    end
  end
end
