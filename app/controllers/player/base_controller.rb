class Player::BaseController < ApplicationController

  before_action :authenticate_player!
  before_action :verify_player!


  private

  def verify_player!
    if current_player.anonymized_at.present?
      sign_out current_player
      redirect_to root_path
    end
  end

  def pundit_user
    current_player
  end

  def refresh_notifications_for(player)
    Turbo::StreamsChannel.broadcast_update_to(
      "notifications_#{player.id}",
      target: "notifications-mobile",
      partial: "player/notifications/navbar_item_mobile",
      locals: { player: }
    )

    Turbo::StreamsChannel.broadcast_update_to(
      "notifications_#{player.id}",
      target: "notifications-desktop",
      partial: "player/notifications/navbar_item_desktop",
      locals: { player: }
    )

    Turbo::StreamsChannel.broadcast_update_to(
      "notifications_#{player.id}",
      target: "notifications-list",
      partial: "player/notifications/index_list",
      locals: { player: }
    )
  end

  def refresh_notifications_bell_for(player)
    Turbo::StreamsChannel.broadcast_update_to(
      "notifications_#{player.id}",
      target: "bell-icon-mobile",
      partial: "player/notifications/bell_icon",
      locals: { player: }
    )

    Turbo::StreamsChannel.broadcast_update_to(
      "notifications_#{player.id}",
      target: "bell-icon-desktop",
      partial: "player/notifications/bell_icon",
      locals: { player: }
    )
  end

end
