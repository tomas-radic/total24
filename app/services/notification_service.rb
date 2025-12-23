# TODO: player is not needed in some methods - refactor

class NotificationService < ApplicationService
  def initialize(player)
    raise ArgumentError, "player is required" if player.nil?

    @player = player
  end

  def mark_all_as_seen
    @player.notifications.update_all(seen_at: Time.current)
    success
  end

  def mark_all_as_read
    destroy_over_aged
    now = Time.current
    @player.notifications.order(created_at: :desc).update_all(seen_at: now, read_at: now)
    success
  end

  def destroy_over_aged
    Noticed::Event.where("created_at < ?", Config.notifications_max_age_days.days.ago).destroy_all
    success
  end
end
