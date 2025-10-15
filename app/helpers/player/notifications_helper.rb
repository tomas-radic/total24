module Player::NotificationsHelper
  def notification_style(notification)
    "u-grey" if notification.read?
  end
end
