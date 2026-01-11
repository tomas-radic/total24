class Player::BaseController < ApplicationController

  before_action :authenticate_player!
  before_action :verify_player!


  private

  def verify_player!
    unless current_player.active?
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

  def broadcast_players_open_to_play
    return unless selected_season.present?

    players_open_to_play = selected_season.players.open_to_play

    Turbo::StreamsChannel.broadcast_update_to(
      "players_open_to_play",
      target: "players_open_to_play",
      partial: "shared/players_open_to_play",
      locals: { players: players_open_to_play, signed_in_player: current_player }
    )

    Turbo::StreamsChannel.broadcast_update_to(
      "players_open_to_play",
      target: "players_open_to_play_top",
      partial: "shared/players_open_to_play",
      locals: { players: players_open_to_play, signed_in_player: current_player }
    )
  end

  def broadcast_match_update(match)
    match.assignments.each do |assignment|
      Turbo::StreamsChannel.broadcast_update_to(
        "match_#{match.id}_for_player_#{assignment.player.id}",
        partial: "matches/match",
        locals: { match: match, player: assignment.player, privacy: false },
        target: "match_#{match.id}"
      )
    end
  end

  def broadcast_matches_have_changed
    Turbo::StreamsChannel.broadcast_update_to "matches",
                        target: "reload_notice",
                        partial: "matches/reload_notice"
  end

end
