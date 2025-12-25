# TODO: player is not needed in some methods - refactor

class NotificationService < ApplicationService
  def initialize(player)
    raise ArgumentError, "player is required" if player.nil?

    @player = player
  end

  def mark_all_as_seen
    @player.notifications.each do |n|
      n.update!(seen_at: Time.current)
    end

    success
  end

  def mark_all_as_read
    destroy_over_aged   # abusing this method to destroy over aged notifications
    now = Time.current

    @player.notifications.each do |n|
      n.update!(seen_at: now, read_at: now)
    end

    success
  end

  def destroy_over_aged
    over_aged = Noticed::Event.where(
      "created_at < ?", Config.notifications_max_age_days.days.ago
    )

    over_aged.each(&:destroy!)
    success
  end
end
