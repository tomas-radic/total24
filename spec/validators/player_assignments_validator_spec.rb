require 'rails_helper'

RSpec.describe PlayerAssignmentsValidator, type: :validator do
  let(:season) { create(:season) }
  let(:player1) { create(:player) }
  let(:player2) { create(:player) }
  let(:player3) { create(:player) }
  let(:player4) { create(:player) }

  before do
    create(:enrollment, season: season, player: player1)
    create(:enrollment, season: season, player: player2)
    create(:enrollment, season: season, player: player3)
    create(:enrollment, season: season, player: player4)
  end

  describe '#validate' do
    context 'when sides are not balanced' do
      it 'adds an error for unbalanced sides' do
        match = build(:match, season: season, kind: :single)
        match.assignments << build(:assignment, match: match, player: player1, side: 1)
        # Side 2 is empty

        validator = PlayerAssignmentsValidator.new
        validator.validate(match)

        expect(match.errors[:base]).to include(PlayerAssignmentsValidator::ERROR_MESSAGE)
      end
    end

    it 'is valid if all players are enrolled' do
      match = build(:match, season: season, kind: :single)
      match.assignments << build(:assignment, match: match, player: player1, side: 1)
      match.assignments << build(:assignment, match: match, player: player2, side: 2)

      validator = PlayerAssignmentsValidator.new
      validator.validate(match)

      expect(match.errors[:base]).not_to include(PlayerAssignmentsValidator::ERROR_MESSAGE)
    end

    it 'is invalid if any player is not enrolled' do
      season.enrollments.find_by(player: player3).destroy!
      match = build(:match, season: season, kind: :single)
      match.assignments << build(:assignment, match: match, player: player1, side: 1)
      match.assignments << build(:assignment, match: match, player: player3, side: 2) # player3 not enrolled

      validator = PlayerAssignmentsValidator.new
      validator.validate(match)

      expect(match.errors[:base]).to include(PlayerAssignmentsValidator::ERROR_MESSAGE)
    end

    context 'single match' do
      it 'is valid with 1 player on each side' do
        match = build(:match, season: season, kind: :single)
        match.assignments << build(:assignment, match: match, player: player1, side: 1)
        match.assignments << build(:assignment, match: match, player: player2, side: 2)

        validator = PlayerAssignmentsValidator.new
        validator.validate(match)

        expect(match.errors[:base]).not_to include(PlayerAssignmentsValidator::ERROR_MESSAGE)
      end

      it 'is invalid with more than 1 player on each side' do
        match = build(:match, season: season, kind: :single)
        match.assignments << build(:assignment, match: match, player: player1, side: 1)
        match.assignments << build(:assignment, match: match, player: player3, side: 1)
        match.assignments << build(:assignment, match: match, player: player2, side: 2)
        match.assignments << build(:assignment, match: match, player: player4, side: 2)

        validator = PlayerAssignmentsValidator.new
        validator.validate(match)

        expect(match.errors[:base]).to include(PlayerAssignmentsValidator::ERROR_MESSAGE)
      end
    end

    context 'double match' do
      it 'is valid with 2 players on each side' do
        match = build(:match, season: season, kind: :double)
        match.assignments << build(:assignment, match: match, player: player1, side: 1)
        match.assignments << build(:assignment, match: match, player: player2, side: 1)
        match.assignments << build(:assignment, match: match, player: player3, side: 2)
        match.assignments << build(:assignment, match: match, player: player4, side: 2)

        validator = PlayerAssignmentsValidator.new
        validator.validate(match)

        expect(match.errors[:base]).not_to include(PlayerAssignmentsValidator::ERROR_MESSAGE)
      end

      it 'is invalid with 1 player on each side' do
        match = build(:match, season: season, kind: :double)
        match.assignments << build(:assignment, match: match, player: player1, side: 1)
        match.assignments << build(:assignment, match: match, player: player2, side: 2)

        validator = PlayerAssignmentsValidator.new
        validator.validate(match)

        expect(match.errors[:base]).to include(PlayerAssignmentsValidator::ERROR_MESSAGE)
      end
    end
  end
end
