class MatchPresenter
  def initialize(match, privacy: false)
    @match = match
    @privacy = privacy
  end

  def side_names(side)
    side_players = @match.assignments.select do |a|
      a.side == side
    end.map(&:player).compact

    return nil if side_players.empty?

    result = PlayerPresenter.new(side_players[0], privacy: @privacy).name
    if side_players[1]
      result += ", #{PlayerPresenter.new(side_players[1], privacy: @privacy).name}"
    end

    result
  end

  def winner_names
    return nil unless @match.reviewed?

    side_names(@match.winner_side)
  end

  def looser_names
    return nil unless @match.reviewed?

    looser_side = @match.winner_side + 1
    looser_side = 1 if looser_side > 2

    side_names(looser_side)
  end

  def result_from_side(side = 1)
    return nil if @match.finished_at.blank?

    side = 1 if (side < 1) || (side > 2)
    other_side = side + 1
    other_side = 1 if other_side > 2

    sets = (1..3).map do |set|
      [
        @match.send("set#{set}_side#{side}_score"),
        @match.send("set#{set}_side#{other_side}_score")
      ].reject(&:blank?).join(':')
    end

    if @match.retired?
      sets << "(skreč)"
    end

    sets.reject(&:blank?).join(", ")
  end

  def label
    "#{side_names(1)} vs. #{side_names(2)}"
  end

  def predictions
    pc = @match.predictions.count
    return nil.to_s if pc.zero?

    predictions_side1 = @match.predictions.count { |p| p.side == 1 }
    "#{predictions_side1}/#{pc - predictions_side1}"
  end
end
