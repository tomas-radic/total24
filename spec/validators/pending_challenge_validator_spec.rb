require 'rails_helper'

RSpec.describe PendingChallengeValidator, type: :validator do
  let(:season) { create(:season, ended_at: 1.day.ago) }
  let(:player1) { create(:player, seasons: [season]) }
  let(:player2) { create(:player, seasons: [season]) }
  let(:player3) { create(:player, seasons: [season]) }
  let(:player4) { create(:player, seasons: [season]) }

  describe '#validate' do
    let(:validator) { PendingChallengeValidator.new }

    context 'when no existing challenges' do
      it 'is valid' do
        match = build(:match, season: season)
        match.assignments << build(:assignment, match: match, player: player1, side: 1)
        match.assignments << build(:assignment, match: match, player: player2, side: 2)

        validator.validate(match)

        expect(match.errors[:base]).not_to include(PendingChallengeValidator::ERROR_MESSAGE)
      end
    end

    context 'when similar pending challenge exists in the same season' do
      before do
        create(:match, :accepted,
               season: season,
               assignments: [
                 build(:assignment, side: 1, player: player2),
                 build(:assignment, side: 2, player: player1)
               ])
      end

      it 'is invalid' do
        match = build(:match, season: season)
        match.assignments << build(:assignment, match: match, player: player1, side: 1)
        match.assignments << build(:assignment, match: match, player: player2, side: 2)

        validator.validate(match)

        expect(match.errors[:base]).to include(PendingChallengeValidator::ERROR_MESSAGE)
      end
    end

    context 'when similar pending challenge exists in a different season' do
      it 'is valid' do
        another_season = create(:season)
        p1 = create(:player, seasons: [another_season])
        p2 = create(:player, seasons: [another_season])
        create(:match, :accepted,
               season: another_season,
               assignments: [
                 build(:assignment, side: 1, player: p1),
                 build(:assignment, side: 2, player: p2)
               ])

        match = build(:match, season: season)
        match.assignments << build(:assignment, match: match, player: player1, side: 1)
        match.assignments << build(:assignment, match: match, player: player2, side: 2)

        validator.validate(match)

        expect(match.errors[:base]).not_to include(PendingChallengeValidator::ERROR_MESSAGE)
      end
    end

    context 'when similar challenge exists but it is not pending (finished)' do
      before do
        create(:match, :finished,
               season: season,
               assignments: [
                 build(:assignment, side: 1, player: player2),
                 build(:assignment, side: 2, player: player1)
               ])
      end

      it 'is valid' do
        match = build(:match, season: season)
        match.assignments << build(:assignment, match: match, player: player1, side: 1)
        match.assignments << build(:assignment, match: match, player: player2, side: 2)

        validator.validate(match)

        expect(match.errors[:base]).not_to include(PendingChallengeValidator::ERROR_MESSAGE)
      end
    end

    context 'when similar challenge exists but it is not published' do
      before do
        create(:match, :accepted,
               season: season,
               published_at: nil,
               assignments: [
                 build(:assignment, side: 1, player: player2),
                 build(:assignment, side: 2, player: player1)
               ])
      end

      it 'is valid' do
        match = build(:match, season: season)
        match.assignments << build(:assignment, match: match, player: player1, side: 1)
        match.assignments << build(:assignment, match: match, player: player2, side: 2)

        validator.validate(match)

        expect(match.errors[:base]).not_to include(PendingChallengeValidator::ERROR_MESSAGE)
      end
    end

    context 'for doubles' do
      context 'when exact same players are in another pending challenge' do
        before do
          create(:match, :accepted,
                 season: season,
                 assignments: [
                   build(:assignment, side: 1, player: player4),
                   build(:assignment, side: 1, player: player3),
                   build(:assignment, side: 2, player: player2),
                   build(:assignment, side: 2, player: player1)
                 ])
        end

        it 'is invalid' do
          match = build(:match, season: season)
          match.assignments << build(:assignment, match: match, player: player1, side: 1)
          match.assignments << build(:assignment, match: match, player: player2, side: 1)
          match.assignments << build(:assignment, match: match, player: player3, side: 2)
          match.assignments << build(:assignment, match: match, player: player4, side: 2)

          validator.validate(match)

          expect(match.errors[:base]).to include(PendingChallengeValidator::ERROR_MESSAGE)
        end
      end

      context 'when exact same players but combined differently are in another pending challenge' do
        before do
          create(:match, :accepted,
                 season: season,
                 assignments: [
                   build(:assignment, side: 1, player: player4),
                   build(:assignment, side: 1, player: player2),
                   build(:assignment, side: 2, player: player3),
                   build(:assignment, side: 2, player: player1)
                 ])
        end

        it 'is valid' do
          match = build(:match, season: season)
          match.assignments << build(:assignment, match: match, player: player1, side: 1)
          match.assignments << build(:assignment, match: match, player: player2, side: 1)
          match.assignments << build(:assignment, match: match, player: player3, side: 2)
          match.assignments << build(:assignment, match: match, player: player4, side: 2)

          validator.validate(match)

          expect(match.errors[:base]).not_to include(PendingChallengeValidator::ERROR_MESSAGE)
        end
      end

      context 'when players are different' do
        before do
          create(:match, :accepted,
                 season: season,
                 assignments: [
                   build(:assignment, side: 1, player: player1),
                   build(:assignment, side: 1, player: player2),
                   build(:assignment, side: 2, player: player3),
                   build(:assignment, side: 2, player: player4)
                 ])
        end

        it 'is valid' do
          player5 = create(:player, seasons: [season])
          match = build(:match, season: season)
          match.assignments << build(:assignment, match: match, player: player1, side: 1)
          match.assignments << build(:assignment, match: match, player: player5, side: 1)
          match.assignments << build(:assignment, match: match, player: player3, side: 2)
          match.assignments << build(:assignment, match: match, player: player4, side: 2)

          validator.validate(match)

          expect(match.errors[:base]).not_to include(PendingChallengeValidator::ERROR_MESSAGE)
        end
      end
    end
  end
end
