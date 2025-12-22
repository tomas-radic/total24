class PlayerService < ApplicationService
  def set_open_to_play(player, open = true)
    if open
      player.update(open_to_play_since: Time.current, cant_play_since: nil)
    else
      player.update(open_to_play_since: nil)
    end
    success(player)
  end

  def set_cant_play(player, can_play = false)
    if can_play
      player.update(cant_play_since: nil)
    else
      player.update(cant_play_since: Time.current, open_to_play_since: nil)
    end
    success(player)
  end

  def get_players_open_to_play(season)
    players = season.players
          .where.not(open_to_play_since: nil)
          .order(open_to_play_since: :desc)
    success(players)
  end
end
