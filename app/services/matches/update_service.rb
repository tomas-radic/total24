class Matches::UpdateService < ApplicationService
  def initialize(current_player)
    @current_player = current_player
  end

  def call(match, params)
    return failure(match.errors.full_messages, value: match) unless match.update(params)

    broadcast_match_update(match)

    recipients = match.notification_recipients_for(MatchUpdatedNotifier)
    recipients = recipients.reject { |recipient| recipient.id == @current_player.id }
    MatchUpdatedNotifier.with(record: match).deliver(recipients)

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
