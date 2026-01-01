class Season < ApplicationRecord
  acts_as_list

  # region Relations
  has_many :tournaments, dependent: :restrict_with_error
  has_many :enrollments, dependent: :restrict_with_error
  has_many :players, through: :enrollments
  has_many :matches, dependent: :restrict_with_error
  has_many :articles, dependent: :destroy
  # endregion Relations

  # region Validations
  validates :name, uniqueness: true
  validates :name, :performance_player_tag_label, :performance_play_off_size,
            :play_off_min_matches_count, :regular_a_play_off_size, :regular_b_play_off_size,
            presence: true

  validates :ended_at,
            presence: true,
            if: Proc.new { |s| Season.where.not(id: s.id).where(ended_at: nil).exists? }
  # endregion Validations

  # region Scopes
  scope :sorted, -> { order(position: :desc) }
  scope :ended, -> { where.not(ended_at: nil) }
  # endregion Scopes


  def ended?
    ended_at.present?
  end

  def ranking
    result = players.includes(:tags, :enrollments)

    played_matches = matches.published.finished.reviewed.singles
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
      player1.points = player1.percentage
      player2.points = player2.percentage
    end

    played_matches.each do |match|
      winner = result.find { |p| p.id == match.assignments.find { |a| a.side == match.winner_side }.player_id }
      looser = result.find { |p| p.id == match.assignments.find { |a| a.side != match.winner_side }.player_id }

      winner.points += looser.percentage
    end

    result = result.reject { |p| p.anonymized? || !p.confirmed? }

    result.sort_by do |player|
      [
        -player.points,
        -player.played_matches,
        player.enrollments.find { |enr| enr.season_id == id }.created_at
      ]
    end
  end


  def play_offs
    all_players = ranking

    perf_players = all_players.select do |p|
      p.tags.find { |t| t.label == performance_player_tag_label }
    end

    rgl_players = all_players.select do |p|
      p.tags.count { |t| t.label == performance_player_tag_label } == 0
    end

    perf_players = nominate_play_off(perf_players, performance_play_off_size)
    rgl_players = nominate_play_off(rgl_players, regular_a_play_off_size + regular_b_play_off_size)

    rgl_a_players = rgl_players[0...regular_a_play_off_size]
    rgl_b_players = rgl_players[regular_a_play_off_size...(regular_a_play_off_size + regular_b_play_off_size)]

    [perf_players, rgl_a_players, rgl_b_players]
  end

  private

  def nominate_play_off(players_group, play_off_size)
    nr_of_extra_players = play_off_size - players_group.count { |p| p.played_matches >= play_off_min_matches_count }

    players_group.reject! do |player|
      next false if player.played_matches >= play_off_min_matches_count

      nr_of_extra_players -= 1
      nr_of_extra_players < 0
    end

    players_group.first(play_off_size)
  end
end
