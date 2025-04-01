class Season < ApplicationRecord
  acts_as_list

  # Relations ----------
  has_many :tournaments, dependent: :restrict_with_error
  has_many :enrollments, dependent: :restrict_with_error
  has_many :players, through: :enrollments
  has_many :matches, as: :competitable, dependent: :restrict_with_error
  has_many :articles, dependent: :destroy


  # Validations --------
  validates :name,
            presence: true, uniqueness: true
  validates :play_off_size,
            :points_single_20,
            :points_single_21,
            :points_single_12,
            :points_single_02,
            :points_double_20,
            :points_double_21,
            :points_double_12,
            :points_double_02,
            presence: true

  validates :ended_at,
            presence: true,
            if: Proc.new { |s| Season.where.not(id: s.id).where(ended_at: nil).exists? }


  # Scopes -----
  scope :sorted, -> { order(position: :desc) }
  scope :ended, -> { where.not(ended_at: nil) }


  def ranking
    result = players.includes(:tags, :enrollments)

    played_matches = matches.published.finished.reviewed.singles
                            .order(:finished_at).includes(assignments: :player)

    played_matches.each do |match|
      player1 = result.find { |p| p.id == match.assignments.find { |a| a.side == 1 }.player_id }
      player2 = result.find { |p| p.id == match.assignments.find { |a| a.side == 2 }.player_id }
      # debugger

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

    result.sort_by do |player|
      [
        -player.points,
        -player.played_matches,
        player.enrollments.find { |enr| enr.season_id == id }.created_at
      ]
    end
  end


  def play_offs
    # debugger
    all_ranking_players = ranking
    min_matches = ENV['PLAY_OFF_MIN_MATCHES_COUNT'].to_i
    perf_play_off_size = (ENV['PERFORMANCE_PLAY_OFF_SIZE'] || 4).to_i
    reg_a_play_off_size = (ENV['REGULAR_A_PLAY_OFF_SIZE'] || 8).to_i
    reg_b_play_off_size = (ENV['REGULAR_B_PLAY_OFF_SIZE'] || 16).to_i

    all_ranking_players.delete_if { |p| p.played_matches < min_matches } if min_matches > 0

    performance_players = all_ranking_players.select do |p|
      p.tags.find { |t| t.label == ENV['PERFORMANCE_PLAYER_TAG_LABEL'] }
    end

    performance_play_off = performance_players.first(perf_play_off_size)
    all_ranking_players.delete_if { |p| p.id.in?(performance_players.map(&:id)) }

    regular_play_off_a = all_ranking_players[0...reg_a_play_off_size]
    regular_play_off_b = all_ranking_players[reg_a_play_off_size...(reg_a_play_off_size + reg_b_play_off_size)]

    [performance_play_off.to_a, regular_play_off_a.to_a, regular_play_off_b.to_a]
  end
end
