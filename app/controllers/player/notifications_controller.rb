class Player::NotificationsController < Player::BaseController
  before_action :load_notification, only: [:show]

  def show
    now = Time.current
    @notification.update(seen_at: now, read_at: now)
    Noticed::Event.where("created_at < ?", 45.days.ago).destroy_all
    redirect_to @notification.url

    # respond_to do |format|
    #   format.html { redirect_back(fallback_location: notifications_path) }
    #   format.json { head :no_content }
    # end
  end

  def mark_all_as_seen
    current_player.notifications.update_all(seen_at: Time.current)

    respond_to do |format|
      format.turbo_stream do
        Turbo::StreamsChannel.broadcast_update_to(
          "notifications_#{current_player.id}",
          target: "bell-icon-mobile",
          partial: "shared/bell_icon",
          locals: { player: current_player }
        )

        Turbo::StreamsChannel.broadcast_update_to(
          "notifications_#{current_player.id}",
          target: "bell-icon-desktop",
          partial: "shared/bell_icon",
          locals: { player: current_player }
        )

        head :ok
      end

      # format.html { redirect_back(fallback_location: root_path) }
    end
  end


  private

  def load_notification
    @notification = current_player.notifications.find(params[:id])
  end
end
