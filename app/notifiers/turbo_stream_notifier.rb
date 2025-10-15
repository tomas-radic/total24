class TurboStreamNotifier < ApplicationNotifier
  validates :record, presence: true

  deliver_by :turbo_stream, class: "DeliveryMethods::TurboStream"

  notification_methods do
    def broadcast_notifications
      broadcast_update_to(
        "notifications_#{recipient.id}",
        target: "notifications-mobile",
        partial: "player/notifications/navbar_item_mobile",
        locals: { player: recipient }
      )

      broadcast_update_to(
        "notifications_#{recipient.id}",
        target: "notifications-desktop",
        partial: "player/notifications/navbar_item_desktop",
        locals: { player: recipient }
      )
    end
  end
end
