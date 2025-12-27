class PlayerAssignmentsValidator < ActiveModel::Validator
  ERROR_MESSAGE = "Nesprávne priradenie hráčov."

  def validate(record)
    @record = record
    @nr_side1_assignments = record.assignments.select { |a| a.side == 1 }.length
    @nr_side2_assignments = record.assignments.select { |a| a.side == 2 }.length

    unless balanced_sides?
      record.errors.add(:base, ERROR_MESSAGE)
      return
    end

    return if @nr_side1_assignments.zero?

    unless all_players_enrolled?
      record.errors.add(:base, ERROR_MESSAGE)
      return
    end

    unless correct_players_count?
      record.errors.add(:base, ERROR_MESSAGE)
      return
    end
  end

  private

  def balanced_sides?
    @nr_side1_assignments == @nr_side2_assignments
  end

  def all_players_enrolled?
    return true unless @record.competitable.is_a?(Season)

    @record.assignments.each do |a|
      return false unless @record.competitable.enrollments.find { |e| e.player_id == a.player_id }
    end

    true
  end

  def correct_players_count?
    if @record.single?
      @nr_side1_assignments == 1
    elsif @record.double?
      @nr_side1_assignments == 2
    end
  end
end
