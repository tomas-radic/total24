class SeasonStandings
  def initialize(season)
    @season = season
  end

  def ranking
    return @ranking if @ranking
    result = @season.players.includes(:tags, :enrollments)

    played_matches = @season.matches.published.finished.reviewed.singles
                            .order(:finished_at).includes(:assignments)

    played_matches.each do |match|
      player1 = result.find { |p| p.id == match.assignments.find { |a| a.side == 1 }.player_id }
      player2 = result.find { |p| p.id == match.assignments.find { |a| a.side == 2 }.player_id }

      player1.played_matches += 1
      player2.played_matches += 1

      case match.winner_side
      when 1
        player1.won_matches += 1
      when 2
        player2.won_matches += 1
      end

      player1.percentage = Percentage.calculate(player1.won_matches, of: player1.played_matches)
      player2.percentage = Percentage.calculate(player2.won_matches, of: player2.played_matches)
    end

    played_matches.each do |match|
      winner = result.find { |p| p.id == match.assignments.find { |a| a.side == match.winner_side }.player_id }
      looser = result.find { |p| p.id == match.assignments.find { |a| a.side != match.winner_side }.player_id }

      winner.points += looser.percentage
    end

    result = result.reject do |p|
      season_enrollment = p.enrollments.find { |enr| enr.season_id == @season.id }
      season_enrollment.nil? || !season_enrollment.active?
    end

    @ranking ||= result.sort_by do |player|
      enrollment = player.enrollments.find { |enr| enr.season_id == @season.id }
      [
        -player.points,
        -player.won_matches,
        -player.played_matches,
        enrollment.created_at
      ]
    end
  end

  def play_offs
    return @play_offs if @play_offs
    all_players = ranking

    perf_players = all_players.select do |p|
      p.tags.find { |t| t.label == Config.performance_player_tag_label }
    end

    rgl_players = all_players.select do |p|
      p.tags.count { |t| t.label == Config.performance_player_tag_label } == 0
    end

    perf_players = nominate_play_off(perf_players, @season.performance_play_off_size)
    rgl_players = nominate_play_off(rgl_players, @season.regular_a_play_off_size + @season.regular_b_play_off_size)

    rgl_a_players = rgl_players[0...@season.regular_a_play_off_size]
    rgl_b_players = rgl_players[@season.regular_a_play_off_size...(@season.regular_a_play_off_size + @season.regular_b_play_off_size)]

    @play_offs ||= [perf_players.to_a, rgl_a_players.to_a, rgl_b_players.to_a]
  end

  private

  def nominate_play_off(players_group, play_off_size)
    nr_of_extra_players = play_off_size - players_group.count { |p| p.played_matches >= @season.play_off_min_matches_count }

    players_group.reject! do |player|
      next false if player.played_matches >= @season.play_off_min_matches_count

      nr_of_extra_players -= 1
      nr_of_extra_players < 0
    end

    players_group.first(play_off_size)
  end
end
