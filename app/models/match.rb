class Match < ApplicationRecord
  include Reactions

  before_validation :set_defaults
  after_commit :broadcast, if: Proc.new { |match| match.published_at.present? }

  # Relations -----
  belongs_to :competitable, polymorphic: true
  belongs_to :place, optional: true
  has_many :assignments, dependent: :destroy
  has_many :players, through: :assignments
  has_many :predictions, dependent: :destroy
  belongs_to :canceled_by, class_name: "Player", optional: true

  # Validations -----
  validates :kind, presence: true
  validates :winner_side, inclusion: { in: [1, 2] }, if: Proc.new { |m| m.finished_at }
  validates :rejected_at, absence: true, if: Proc.new { |m| m.accepted_at }
  validates :accepted_at, absence: true, if: Proc.new { |m| m.rejected_at }
  validates :requested_at, presence: true, if: Proc.new { |m| m.accepted_at || m.rejected_at }
  validates :finished_at, presence: true, if: Proc.new { |m| m.reviewed_at }
  validates :finished_at, absence: true, if: Proc.new { |m| m.competitable_type == "Season" && m.accepted_at.nil? }
  validates :canceled_at, absence: true, if: Proc.new { |m| m.finished_at || m.rejected_at }
  validates :canceled_at, absence: true, if: Proc.new { |m| m.accepted_at.nil? && m.rejected_at.nil? }
  validates :canceled_at, presence: true, if: Proc.new { |m| m.canceled_by_id.present? }
  validates :canceled_by_id, presence: true, if: Proc.new { |m| m.canceled_at }
  validates :play_date, :play_time, :place_id,
            absence: true, if: Proc.new { |m| m.competitable_type == "Season" && m.requested_at && m.accepted_at.blank? }
  validates :winner_side,
            presence: true, if: Proc.new { |m| m.finished_at }
  validates :set1_side1_score, presence: true, if: Proc.new { |m| m.set1_side2_score.present? }
  validates :set1_side2_score, presence: true, if: Proc.new { |m| m.set1_side1_score.present? }
  validates :set2_side1_score, presence: true, if: Proc.new { |m| m.set2_side2_score.present? }
  validates :set2_side2_score, presence: true, if: Proc.new { |m| m.set2_side1_score.present? }
  validates :set3_side1_score, presence: true, if: Proc.new { |m| m.set3_side2_score.present? }
  validates :set3_side2_score, presence: true, if: Proc.new { |m| m.set3_side1_score.present? }
  validate :result_state, if: Proc.new { |m| m.finished_at }
  validate :player_assignments
  validate :existing_matches, if: Proc.new { |m| m.single? && m.finished_at.blank? && m.competitable_type == "Season" }

  # Enums -----
  enum :kind, {
    single: 0,
    double: 1
  }

  enum :play_time, [
    "6:00", "6:30", "7:00", "7:30", "8:00", "8:30", "9:00", "9:30", "10:00", "10:30",
    "11:00", "11:30", "12:00", "12:30", "13:00", "13:30", "14:00", "14:30", "15:00", "15:30",
    "16:00", "16:30", "17:00", "17:30", "18:00", "18:30", "19:00", "19:30", "20:00", "20:30",
    "21:00", "21:30", "22:00"
  ]

  # Scopes
  scope :sorted, -> { order(finished_at: :desc) }
  scope :published, -> { where.not(published_at: nil) }
  scope :requested, -> { where.not(requested_at: nil).where(accepted_at: nil, rejected_at: nil, canceled_at: nil) }
  scope :accepted, -> { where.not(accepted_at: nil) }
  scope :rejected, -> { where.not(rejected_at: nil) }
  scope :pending, -> { where(rejected_at: nil, finished_at: nil, canceled_at: nil) }
  scope :in_season, ->(season) { where(competitable_type: "Season", competitable_id: season.id) }
  scope :finished, -> { where.not(finished_at: nil) }
  scope :reviewed, -> { where.not(reviewed_at: nil) }
  scope :canceled, -> { where.not(canceled_at: nil) }
  scope :ranking_counted, -> { where(ranking_counted: true) }
  scope :singles, -> { where(kind: "single") }
  scope :doubles, -> { where(kind: "double") }

  def played_3rd_set?
    set3_side1_score.present? || set3_side2_score.present?
  end

  def winner_name(privacy: false)
    return nil unless reviewed?

    assignments.select do |a|
      a.side == winner_side
    end.map { |a| a.player.display_name(privacy:) }.join(", ")
  end

  def looser_name(privacy: false)
    return nil unless reviewed?

    assignments.select do |a|
      a.side != winner_side
    end.map { |a| a.player.display_name(privacy:) }.join(", ")
  end

  def result(side: 1)
    return nil if finished_at.blank?

    side = 1 if (side < 1) || (side > 2)
    other_side = side - 1
    other_side = 2 if other_side < 1

    sets = (1..3).map do |set|
      [
        send("set#{set}_side#{side}_score"),
        send("set#{set}_side#{other_side}_score")
      ].reject(&:blank?).join(':')
    end

    if retired?
      sets << "(skreč)"
    end

    sets.reject(&:blank?).join(", ")
  end

  def side_name(side, privacy: false)
    assignments.select do |a|
      a.side == side
    end.map { |a| a.player.display_name(privacy:) }.join(", ")
  end

  def predictions_text
    pc = predictions.count

    if pc > 0
      predictions_side1 = predictions.count { |p| p.side == 1 }
      "#{predictions_side1}/#{pc - predictions_side1}"
    end
  end

  def date
    play_date.presence || finished_at.presence
  end

  def published?
    published_at.present?
  end

  def requested?
    requested_at && accepted_at.blank? && rejected_at.blank? && finished_at.blank?
  end

  def accepted?
    accepted_at.present?
  end

  def rejected?
    rejected_at.present?
  end

  def finished?
    finished_at.present?
  end

  def reviewed?
    reviewed_at.present?
  end

  def canceled?
    canceled_at.present?
  end

  def retired?
    assignments.find { |a| a.is_retired? }
  end

  def finish(attributes = {})
    score = attributes["score"].strip.split(//)

    unless score.length.in?([0, 2, 4, 6])
      self.errors.add(:score, "Neplatný výsledok zápasu.")
      return self
    end

    ActiveRecord::Base.transaction do
      finish_time = finished_at
      review_time = reviewed_at
      unfinish!
      now = Time.now
      side = attributes["score_side"]
      set_nr = 0

      score.each.with_index do |s, idx|
        set_nr += 1 if (idx % 2) == 0

        send("set#{set_nr}_side#{side}_score=", s)

        side += 1
        side = 1 if side > 2
      end

      if attributes["retired_player_id"].present?
        retired_assignment = self.assignments.find { |a| a.player_id == attributes["retired_player_id"] }
        retired_assignment.update(is_retired: true)
        self.winner_side = retired_assignment.side + 1
        self.winner_side = 1 if self.winner_side > 2
      else
        side1 = 0

        if set1_side1_score.present? || set1_side2_score.present?
          s1 = set1_side1_score.to_i
          s2 = set1_side2_score.to_i
          side1 += (s1 - s2 > 0) ? 1 : -1
        end

        if set2_side1_score.present? || set2_side2_score.present?
          s1 = set2_side1_score.to_i
          s2 = set2_side2_score.to_i
          side1 += (s1 - s2 > 0) ? 1 : -1
        end

        if set3_side1_score.present? || set3_side2_score.present?
          s1 = set3_side1_score.to_i
          s2 = set3_side2_score.to_i
          side1 += (s1 - s2 > 0) ? 1 : -1
        end

        if side1 > 0
          self.winner_side = 1
        elsif side1 < 0
          self.winner_side = 2
        end

        if self.winner_side.nil?
          self.errors.add(:score, "Neplatný výsledok zápasu.")
          return self
        end
      end

      self.play_date = attributes["play_date"]
      self.place_id = attributes["place_id"]
      self.notes = attributes["notes"]
      self.finished_at = finish_time || now
      self.reviewed_at = review_time || now
      save
    end

    self
  end

  def unfinish!
    ActiveRecord::Base.transaction do
      update!(finished_at: nil,
              reviewed_at: nil,
              winner_side: nil,
              set1_side1_score: nil,
              set1_side2_score: nil,
              set2_side1_score: nil,
              set2_side2_score: nil,
              set3_side1_score: nil,
              set3_side2_score: nil)

      assignments.each do |a|
        a.update!(is_retired: false)
      end
    end
  end

  def season
    if competitable.is_a?(Season)
      competitable
    elsif competitable.is_a?(Tournament)
      competitable.season
    end
  end

  def recently_finished?
    finished_at.present? && finished_at >= 7.days.ago
  end

  def recently_rejected?
    rejected_at.present? && rejected_at > 48.hours.ago
  end

  def recently_canceled?
    canceled_at.present? && canceled_at > 30.hours.ago
  end


  def self.singles_with_players(player1, player2, competitable: nil)
    result = singles.published
    result = result.where(competitable:) if competitable.present?
    result.joins("join assignments side1 on side1.match_id = matches.id and side1.side = 1 join assignments side2 on side2.match_id = matches.id and side2.side = 2")
          .where("(side1.player_id = ? and side2.player_id = ?) or (side1.player_id = ? and side2.player_id = ?)", player1.id, player2.id, player2.id, player1.id)
  end


  private

  def player_assignments
    nr_assignments = assignments.length
    nr_side1_assignments = assignments.select { |a| a.side == 1 }.length
    nr_side2_assignments = assignments.select { |a| a.side == 2 }.length

    if nr_assignments > 0
      if (single? && (nr_assignments != 2 || nr_side1_assignments != 1 || nr_side2_assignments != 1)) ||
        (double? && (nr_assignments != 4 || nr_side1_assignments != 2 || nr_side2_assignments != 2))
        errors.add(:base, "Nesprávny počet hráčov.")
      end
    end

    assignments.each do |a|
      if finished_at.nil? && a.player.anonymized_at.present?
        errors.add(:base, "Hráč/ka si zrušil/a registráciu.")
      end

      if competitable.is_a? Season
        unless competitable.enrollments.find { |e| e.player_id == a.player_id }
          errors.add(:base, "Hráč/ka nie je prihlásený/á do sezóny.")
        end
      end
    end

  end

  def existing_matches
    matches = competitable.matches.published.singles.where(finished_at: nil, rejected_at: nil, canceled_at: nil)
                          .where.not(id: id)
                          .joins(:assignments)
                          .where(
                            "assignments.player_id in (?)",
                            assignments.map(&:player_id))
                          .includes(:assignments).distinct

    existing_match = matches.find do |m|
      m.assignments.find { |a| a.player_id == assignments[0].player_id } &&
        m.assignments.find { |a| a.player_id == assignments[1].player_id }
    end

    if existing_match
      errors.add(:base, "Takáto výzva už existuje.")
    end
  end

  def result_state
    unless assignments.find { |a| a.is_retired? }
      if (set1_side1_score.present? || set1_side2_score.present?) && (set1_side1_score == set1_side2_score)
        errors.add(:set1_side2_score, "Skóre v sete nemôže byť pre obe strany rovnaké.")
      end

      if (set2_side1_score.present? || set2_side2_score.present?) && (set2_side1_score == set2_side2_score)
        errors.add(:set2_side2_score, "Skóre v sete nemôže byť pre obe strany rovnaké.")
      end

      if (set3_side1_score.present? || set3_side2_score.present?) && (set3_side1_score == set3_side2_score)
        errors.add(:set3_side2_score, "Skóre v sete nemôže byť pre obe strany rovnaké.")
      end

      side1 = 0

      if set1_side1_score.present? || set1_side2_score.present?
        s1 = set1_side1_score.to_i
        s2 = set1_side2_score.to_i
        errors.add(:set1_side2_score, "Skóre v sete nemôže byť pre obe strany rovnaké.") if s1 == s2
        side1 += (s1 - s2 > 0) ? 1 : -1
      end

      if set2_side1_score.present? || set2_side2_score.present?
        s1 = set2_side1_score.to_i
        s2 = set2_side2_score.to_i
        errors.add(:set2_side2_score, "Skóre v sete nemôže byť pre obe strany rovnaké.") if s1 == s2
        side1 += (s1 - s2 > 0) ? 1 : -1
      end

      if set3_side1_score.present? || set3_side2_score.present?
        s1 = set3_side1_score.to_i
        s2 = set3_side2_score.to_i
        errors.add(:set3_side2_score, "Skóre v sete nemôže byť pre obe strany rovnaké.") if s1 == s2
        side1 += (s1 - s2 > 0) ? 1 : -1
      end

      errors.add(:base, "Neplatné skóre.") if side1 == 0 && !retired?
    end
  end

  def set_defaults
    case assignments.length
    when 2
      self.kind = :single
    when 4
      self.kind = :double
    end
  end

  def broadcast
    broadcast_update_to "matches",
                        target: "matches_index_reload_notice",
                        partial: "matches/matches_reload_notice"

    broadcast_update_to "matches",
                        target: "today_index_reload_notice",
                        partial: "today/matches_reload_notice"
  end
end
