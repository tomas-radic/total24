class Matches::AcceptService < ApplicationService
  def initialize(current_player)
    @current_player = current_player
  end

  def call(match)
    errors = []

    ActiveRecord::Base.transaction do
      unless match.update(accepted_at: Time.current)
        errors += match.errors.full_messages
        raise ActiveRecord::Rollback
      end

      match.players.update_all(open_to_play_since: nil)
    end

    return failure(errors, value: match) if errors.any?

    players_open_to_play = Player.where.not(open_to_play_since: nil)
                                 .order(open_to_play_since: :desc)

    broadcast_players_open_to_play(players_open_to_play)
    broadcast_match_update(match)

    challenger = match.assignments.find { |a| a.side == 1 }.player
    MatchAcceptedNotifier.with(record: match).deliver(challenger)

    success(match)
  rescue ActiveRecord::Rollback
    failure(errors, value: match)
  end

  private

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

  def broadcast_players_open_to_play(players)
    Turbo::StreamsChannel.broadcast_update_to(
      "players_open_to_play",
      target: "players_open_to_play",
      partial: "shared/players_open_to_play",
      locals: { players: players, signed_in_player: @current_player }
    )

    Turbo::StreamsChannel.broadcast_update_to(
      "players_open_to_play",
      target: "players_open_to_play_top",
      partial: "shared/players_open_to_play",
      locals: { players: players, signed_in_player: @current_player }
    )
  end
end
