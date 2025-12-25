class Matches::MarkNotificationsReadService < ApplicationService
  def initialize(current_player)
    @current_player = current_player
  end

  def call(match)
    now = Time.current
    notifications = match.notifications.where(recipient: @current_player).where(read_at: nil)
    notifications.each do |n|
      n.update!(seen_at: now, read_at: now)
    end

    success
  end
end
