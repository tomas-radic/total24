class Matches::CreateService < ApplicationService
  def initialize(current_player)
    @current_player = current_player
  end

  def call(season, requested_player)
    now = Time.current
    match = season.matches.new(
      published_at: now,
      assignments: [
        Assignment.new(player: @current_player, side: 1),
        Assignment.new(player: requested_player, side: 2)
      ]
    )

    ActiveRecord::Base.transaction do
      return failure(match.errors.full_messages, value: match) unless match.save
      @current_player.update!(cant_play_since: nil)
    end

    success(match)
  rescue ActiveRecord::Rollback
    failure(match.errors.full_messages, value: match)
  end
end
