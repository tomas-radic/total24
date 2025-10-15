class Player::NotificationsController < Player::BaseController
  before_action :load_notification, only: [:show]

  def index
    @notifications = current_player.notifications.order(created_at: :desc)
  end

  def show
    now = Time.current
    @notification.update(seen_at: now, read_at: now)
    redirect_to @notification.url

    # respond_to do |format|
    #   format.html { redirect_back(fallback_location: notifications_path) }
    #   format.json { head :no_content }
    # end
  end

  def mark_all_seen
    current_player.notifications.update_all(seen_at: Time.current)

    respond_to do |format|
      format.turbo_stream do
        refresh_notifications_bell_for(current_player)
        head :ok
      end

      # format.html { redirect_back(fallback_location: root_path) }
    end
  end


  def mark_all_read
    destroy_over_aged
    now = Time.current
    @notifications = current_player.notifications.order(created_at: :desc)
    @notifications.update_all(seen_at: now, read_at: now)

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

  def destroy_over_aged
    Noticed::Event.where("created_at < ?", Config.notifications_max_age_days.days.ago).destroy_all
  end
end
