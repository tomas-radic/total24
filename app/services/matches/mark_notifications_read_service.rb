class Matches::MarkNotificationsReadService < ApplicationService
  def initialize(current_player)
    @current_player = current_player
  end

  def call(notifications_subject)
    now = Time.current
    notifications = notifications_subject.notifications.where(recipient: @current_player).where(read_at: nil)
    notifications.each do |n|
      n.update!(seen_at: now, read_at: now)
    end

    success
  end
end
