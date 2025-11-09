class Player::NotificationsController < Player::BaseController
  before_action :load_notification, only: [:show]

  def index
    @notifications = current_player.notifications.order(created_at: :desc)
  end

  def show
    redirect_to @notification.url
  end

  def mark_all_seen
    notification_service.mark_all_as_seen

    respond_to do |format|
      format.turbo_stream do
        refresh_notifications_bell_for(current_player)
        head :ok
      end
    end
  end


  def mark_all_read
    notification_service.mark_all_as_read
    @notifications = current_player.notifications.order(created_at: :desc)

    respond_to do |format|
      format.turbo_stream do
        refresh_notifications_for(current_player)
      end

      format.html { redirect_back(fallback_location: root_path) }
      format.any { head :ok }
    end
  end


  private

  def load_notification
    @notification = current_player.notifications.find(params[:id])
  end

  def notification_service
    @notification_service ||= NotificationService.new(current_player)
  end
end
