class MatchService < ApplicationService
  def initialize(current_player)
    raise ArgumentError, "current_player is required" if current_player.nil?

    @current_player = current_player
  end

  def create(season, requested_player)
    now = Time.current
    match = season.matches.new(
      requested_at: now,
      published_at: now,
      ranking_counted: true,
      assignments: [
        Assignment.new(player: @current_player, side: 1),
        Assignment.new(player: requested_player, side: 2)
      ]
    )

    return failure(match.errors.full_messages, value: match) unless match.save

    @current_player.update(cant_play_since: nil)
    NewMatchNotifier.with(record: match).deliver(requested_player)
    success(match)
  end

  def update(match, params)
    return failure(match.errors.full_messages, value: match) unless match.update(params)

    broadcast_match_update(match)

    recipients = match.notification_recipients_for(MatchUpdatedNotifier)
    recipients = recipients.reject { |recipient| recipient.id == @current_player.id }
    MatchUpdatedNotifier.with(record: match).deliver(recipients)

    success(match)
  end

  def accept(match)
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
  end

  def reject(match)
    return failure(match.errors.full_messages, value: match) unless match.update(rejected_at: Time.current)

    broadcast_match_update(match)

    challenger = match.assignments.find { |a| a.side == 1 }.player
    MatchRejectedNotifier.with(record: match).deliver(challenger)

    success(match)
  end


  def cancel(match)
    return failure(match.errors.full_messages, value: match) unless match.update(canceled_at: Time.current, canceled_by: @current_player)

    broadcast_match_update(match)

    recipients = match.notification_recipients_for(MatchCanceledNotifier)
    recipients = recipients.reject { |recipient| recipient.id == @current_player.id }
    MatchCanceledNotifier.with(record: match).deliver(recipients)

    success(match)
  end

  def toggle_reaction(match)
    reaction = Reaction.find_by(reactionable: match, player: @current_player)

    if reaction.present?
      reaction.destroy!
    else
      Reaction.create!(reactionable: match, player: @current_player)
    end

    success(match.reload)
  end

  def switch_prediction(match, side)
    prediction = match.predictions.find_by(player: @current_player)

    if prediction.present?
      if side.to_i == prediction.side
        prediction.destroy
      else
        prediction.update(side: side)
      end
    else
      match.predictions.create!(player: @current_player, side: side)
    end

    success(match.reload)
  end

  def mark_notifications_read(match)
    now = Time.current
    match.notifications.where(recipient: @current_player)
         .where(read_at: nil)
         .update_all(seen_at: now, read_at: now)
    success
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
