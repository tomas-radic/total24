class PlayerService
  attr_reader :errors

  def initialize
    @errors = []
  end

  def set_open_to_play(player, open = true)
    if open
      player.update(open_to_play_since: Time.current, cant_play_since: nil)
    else
      player.update(open_to_play_since: nil)
    end
  end

  def set_cant_play(player, can_play = false)
    if can_play
      player.update(cant_play_since: nil)
    else
      player.update(cant_play_since: Time.current, open_to_play_since: nil)
    end
  end

  def get_players_open_to_play(season)
    season.players
          .where.not(open_to_play_since: nil)
          .order(open_to_play_since: :desc)
  end
end
