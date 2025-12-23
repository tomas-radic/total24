class Matches::MarkNotificationsReadService < ApplicationService
  def initialize(current_player)
    @current_player = current_player
  end

  def call(match)
    now = Time.current
    match.notifications.where(recipient: @current_player)
         .where(read_at: nil)
         .update_all(seen_at: now, read_at: now)
    success
  end
end
