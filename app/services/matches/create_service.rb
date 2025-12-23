class Matches::CreateService < ApplicationService
  def initialize(current_player)
    @current_player = current_player
  end

  def call(season, requested_player)
    now = Time.current
    match = season.matches.new(
      requested_at: now,
      published_at: now,
      ranking_counted: true,
      assignments: [
        Assignment.new(player: @current_player, side: 1),
        Assignment.new(player: requested_player, side: 2)
      ]
    )

    return failure(match.errors.full_messages, value: match) unless match.save

    @current_player.update(cant_play_since: nil)
    NewMatchNotifier.with(record: match).deliver(requested_player)
    success(match)
  end
end
