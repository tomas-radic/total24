class Matches::FinishService < ApplicationService
  def initialize(current_player)
    @current_player = current_player
  end

  def call(match, params)
    score_side = match.assignments.find { |a| a.player_id == @current_player.id }.side
    params = params.merge("score_side" => score_side)

    ActiveRecord::Base.transaction do
      Matches::UnfinishService.new(@current_player).call(match)

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

      success(match)
    end
  rescue ActiveRecord::Rollback
    failure(match.errors.full_messages, value: match)
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
