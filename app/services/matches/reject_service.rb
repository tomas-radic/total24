class Matches::RejectService < ApplicationService
  def call(match)
    return failure(match.errors.full_messages, value: match) unless match.update(rejected_at: Time.current)

    broadcast_match_update(match)

    challenger = match.assignments.find { |a| a.side == 1 }.player
    MatchRejectedNotifier.with(record: match).deliver(challenger)

    success(match)
  end

  private

  def broadcast_match_update(match)
    match.assignments.each do |assignment|
      Turbo::StreamsChannel.broadcast_update_to(
        "match_#{match.id}_for_player_#{assignment.player.id}",
        partial: "matches/match",
        locals: { match: match, player: assignment.player, privacy: false },
        target: "match_#{match.id}"
      )
    end
  end
end
