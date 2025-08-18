class DeliveryMethods::TurboStream < ApplicationDeliveryMethod
  def deliver
    return unless recipient.is_a?(Player)

    notification.broadcast_notifications
    # notification.broadcast_replace_to_index_count
    # notification.broadcast_prepend_to_index_list
  end
end
