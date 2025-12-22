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

  def finish(match, params)
    score_side = match.assignments.find { |a| a.player_id == @current_player.id }.side
    params = params.merge("score_side" => score_side)

    ActiveRecord::Base.transaction do
      unfinish!(match)

      score = params["score"].to_s.strip.split(//)
      unless score.length.in?([0, 2, 4, 6])
        return failure(["Neplatný výsledok zápasu."], value: match)
      end

      set_scores(match, score, params["score_side"])

      if params["retired_player_id"].present?
        handle_retirement(match, params["retired_player_id"])
      else
        determine_winner(match)
      end

      if match.winner_side.nil?
        return failure(["Neplatný výsledok zápasu."], value: match)
      end

      match.play_date = params["play_date"]
      match.place_id = params["place_id"]
      match.notes = params["notes"]
      match.finished_at ||= Time.current
      match.reviewed_at ||= Time.current

      unless match.save
        return failure(match.errors.full_messages, value: match)
      end

      broadcast_match_update(match)

      opponent = match.assignments.find { |a| a.player_id != @current_player.id }.player
      MatchFinishedNotifier.with(record: match, finished_by: @current_player).deliver(opponent)

      success(match)
    end
  rescue ActiveRecord::Rollback
    failure(match.errors.full_messages, value: match)
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

  def unfinish!(match)
    match.update!(finished_at: nil,
                  reviewed_at: nil,
                  winner_side: nil,
                  set1_side1_score: nil,
                  set1_side2_score: nil,
                  set2_side1_score: nil,
                  set2_side2_score: nil,
                  set3_side1_score: nil,
                  set3_side2_score: nil)

    match.assignments.each do |a|
      a.update!(is_retired: false)
    end
  end

  private
  
  def set_scores(match, score, side)
    set_nr = 0
    score.each.with_index do |s, idx|
      set_nr += 1 if (idx % 2) == 0
      match.send("set#{set_nr}_side#{side}_score=", s)

      side += 1
      side = 1 if side > 2
    end
  end

  def handle_retirement(match, retired_player_id)
    retired_assignment = match.assignments.find { |a| a.player_id == retired_player_id }
    retired_assignment.update(is_retired: true)
    match.winner_side = retired_assignment.side + 1
    match.winner_side = 1 if match.winner_side > 2
  end

  def determine_winner(match)
    side1_wins = 0

    (1..3).each do |set_nr|
      s1 = match.send("set#{set_nr}_side1_score")
      s2 = match.send("set#{set_nr}_side2_score")

      if s1.present? || s2.present?
        side1_wins += ((s1.to_i - s2.to_i) > 0) ? 1 : -1
      end
    end

    if side1_wins > 0
      match.winner_side = 1
    elsif side1_wins < 0
      match.winner_side = 2
    end
  end
end
