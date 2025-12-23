class Matches::CancelService < ApplicationService
  def initialize(current_player)
    @current_player = current_player
  end

  def call(match)
    return failure(match.errors.full_messages, value: match) unless match.update(canceled_at: Time.current, canceled_by: @current_player)

    broadcast_match_update(match)

    recipients = match.notification_recipients_for(MatchCanceledNotifier)
    recipients = recipients.reject { |recipient| recipient.id == @current_player.id }
    MatchCanceledNotifier.with(record: match).deliver(recipients)

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
