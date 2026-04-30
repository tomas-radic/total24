class Matches::ScoreValidator
  def self.call(score_string)
    new(score_string).validate
  end

  def initialize(score_string)
    @score_string = score_string.to_s.strip
  end

  def validate
    return false unless @score_string.match?(/^(\d{4}|\d{6})$/)

    sets = @score_string.scan(/\d{2}/).map { |s| [s[0].to_i, s[1].to_i] }
    
    side1_sets = 0
    side2_sets = 0

    sets.each_with_index do |(s1, s2), index|
      if index < 2
        return false unless valid_regular_set?(s1, s2)
      else
        return false unless valid_third_set?(s1, s2)
      end

      if s1 > s2
        side1_sets += 1
      elsif s2 > s1
        side2_sets += 1
      else
        return false
      end
    end

    return false unless side1_sets == 2 || side2_sets == 2
    
    if sets.length == 3
      s1_1, s2_1 = sets[0]
      s1_2, s2_2 = sets[1]
      
      set1_winner = s1_1 > s2_1 ? 1 : 2
      set2_winner = s1_2 > s2_2 ? 1 : 2
      
      return false if set1_winner == set2_winner
    end

    true
  end

  private

  def valid_regular_set?(s1, s2)
    if s1 == 6
      return true if (0..4).include?(s2)
    end
    if s2 == 6
      return true if (0..4).include?(s1)
    end
    if s1 == 7
      return true if (5..6).include?(s2)
    end
    if s2 == 7
      return true if (5..6).include?(s1)
    end
    false
  end

  def valid_third_set?(s1, s2)
    # Same as regular set OR until 3 games won (3:0, 3:1, 3:2)
    return true if valid_regular_set?(s1, s2)

    if s1 == 3
      (0..2).include?(s2)
    elsif s2 == 3
      (0..2).include?(s1)
    else
      false
    end
  end
end
