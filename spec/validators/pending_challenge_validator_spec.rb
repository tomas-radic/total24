require 'rails_helper'

RSpec.describe PendingChallengeValidator do
  subject { Match.new(competitable: season, assignments: assignments, kind: assignments.length == 2 ? :single : :double) }

  let(:season) { create(:season) }
  let!(:player1) { create(:player, name: "Player 1", seasons: [season]) }
  let!(:player2) { create(:player, name: "Player 2", seasons: [season]) }
  let(:assignments) do
    [
      build(:assignment, side: 1, player: player1),
      build(:assignment, side: 2, player: player2)
    ]
  end

  context "when no existing challenges" do
    it "is valid" do
      expect(subject).to be_valid
    end
  end

  context "when similar pending challenge exists in the same season" do
    let!(:existing_challenge) do
      create(:match,
             competitable: season,
             published_at: Time.now,
             assignments: [
               build(:assignment, side: 1, player: player2),
               build(:assignment, side: 2, player: player1)
             ])
    end

    it "is invalid" do
      expect(subject).not_to be_valid
      expect(subject.errors[:base]).to include(PendingChallengeValidator::ERROR_MESSAGE)
    end
  end

  context "when similar pending challenge exists in a different season" do
    it "is valid" do
      another_season = create(:season, name: "Another Season #{SecureRandom.hex}", ended_at: Time.now)
      
      p1 = create(:player, name: "Player A #{SecureRandom.hex}", seasons: [another_season])
      p2 = create(:player, name: "Player B #{SecureRandom.hex}", seasons: [another_season])
      create(:match,
             competitable: another_season,
             published_at: Time.now,
             assignments: [
               build(:assignment, side: 1, player: p1),
               build(:assignment, side: 2, player: p2)
             ])
             
      expect(subject).to be_valid
    end
  end

  context "when similar challenge exists but it is not pending (finished)" do
    let!(:existing_challenge) do
      create(:match, :finished,
             competitable: season,
             assignments: [
               build(:assignment, side: 1, player: player2),
               build(:assignment, side: 2, player: player1)
             ])
    end

    it "is valid" do
      expect(subject).to be_valid
    end
  end

  context "when similar challenge exists but it is not published" do
    let!(:existing_challenge) do
      create(:match,
             competitable: season,
             published_at: nil,
             assignments: [
               build(:assignment, side: 1, player: player2),
               build(:assignment, side: 2, player: player1)
             ])
    end

    it "is valid" do
      expect(subject).to be_valid
    end
  end

  context "for doubles" do
    let!(:player3) { create(:player, name: "Player 3", seasons: [season]) }
    let!(:player4) { create(:player, name: "Player 4", seasons: [season]) }
    let(:assignments) do
      [
        build(:assignment, side: 1, player: player1),
        build(:assignment, side: 1, player: player2),
        build(:assignment, side: 2, player: player3),
        build(:assignment, side: 2, player: player4)
      ]
    end

    context "when exact same players are in another pending challenge" do
      let!(:existing_challenge) do
        create(:match,
               competitable: season,
               published_at: Time.now,
               assignments: [
                 build(:assignment, side: 1, player: player4),
                 build(:assignment, side: 1, player: player3),
                 build(:assignment, side: 2, player: player2),
                 build(:assignment, side: 2, player: player1)
               ])
      end

      it "is invalid" do
        expect(subject).not_to be_valid
        expect(subject.errors[:base]).to include(PendingChallengeValidator::ERROR_MESSAGE)
      end
    end

    context "when exact same players but combined differently are in another pending challenge" do
      let!(:existing_challenge) do
        create(:match,
               competitable: season,
               published_at: Time.now,
               assignments: [
                 build(:assignment, side: 1, player: player4),
                 build(:assignment, side: 1, player: player2),
                 build(:assignment, side: 2, player: player3),
                 build(:assignment, side: 2, player: player1)
               ])
      end

      it "is valid" do
        expect(subject).to be_valid
      end
    end

    context "when players are different" do
      let!(:player5) { create(:player, name: "Player 5", seasons: [season]) }
      let(:assignments) do
        [
          build(:assignment, side: 1, player: player1),
          build(:assignment, side: 1, player: player5),
          build(:assignment, side: 2, player: player3),
          build(:assignment, side: 2, player: player4)
        ]
      end

      let!(:existing_challenge) do
        create(:match,
               competitable: season,
               published_at: Time.now,
               assignments: [
                 build(:assignment, side: 1, player: player1),
                 build(:assignment, side: 1, player: player2),
                 build(:assignment, side: 2, player: player3),
                 build(:assignment, side: 2, player: player4)
               ])
      end

      it "is valid" do
        expect(subject).to be_valid
      end
    end
  end
end
