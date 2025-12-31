class PendingChallengeValidator < ActiveModel::Validator
  ERROR_MESSAGE = "Takáto výzva už existuje."

  def validate(record)
    record_player_ids = match_player_ids(record)
    return if record_player_ids.any?(&:empty?)

    existing_challenges = record.season.matches.published.pending.where.not(id: record.id)
    existing_challenges.each do |challenge|
      challenge_player_ids = match_player_ids(challenge)
      if challenge_player_ids == record_player_ids
        record.errors.add(:base, ERROR_MESSAGE)
        return
      end
    end
  end

  private

  def match_player_ids(match)
    side1_player_ids = match.assignments.select { |a| a.side == 1 }.map(&:player_id).sort
    side2_player_ids = match.assignments.select { |a| a.side == 2 }.map(&:player_id).sort
    [side1_player_ids, side2_player_ids].sort
  end
end
