class Match < ApplicationRecord
  include Reactions

  #region Callbacks
  before_validation :set_defaults
  after_commit :broadcast, if: Proc.new { |match| match.published_at.present? }
  #endregion Callbacks

  #region Relations
  belongs_to :competitable, polymorphic: true
  belongs_to :place, optional: true
  belongs_to :canceled_by, class_name: "Player", optional: true
  has_many :assignments, dependent: :destroy
  has_many :players, through: :assignments
  has_many :challenger_players, -> { where(assignments: { side: 1 }) }, through: :assignments, source: :player
  has_many :challenged_players, -> { where(assignments: { side: 2 }) }, through: :assignments, source: :player
  has_many :predictions, dependent: :destroy
  has_many :noticed_events, as: :record, dependent: :destroy, class_name: "Noticed::Event"
  has_many :notifications, through: :noticed_events, class_name: "Noticed::Notification"
  #endregion Relations

  #region Validations
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

  validates_with PendingChallengeValidator
  validates_with PlayerAssignmentsValidator
  #endregion Validations

  #region Enums
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
  #endregion Enums

  #region Scopes
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
  #endregion Scopes

  def opponents_of(player)
    opponents_side = assignments.find { |a| a.player_id == player.id }&.side
    return nil if opponents_side.nil?
    players.where.not(assignments: { side: opponents_side })
  end

  def date
    play_date.presence || finished_at.presence
  end

  def published?
    published_at.present?
  end

  def requested?
    requested_at.present?
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
    assignments.any? { |a| a.is_retired? }
  end

  def season
    if competitable.is_a?(Season)
      competitable
    elsif competitable.is_a?(Tournament)
      competitable.season
    end
  end

  def recently_finished?
    finished_at.present? && finished_at >= 3.days.ago.beginning_of_day
  end

  def recently_rejected?
    rejected_at.present? && rejected_at > 48.hours.ago
  end

  def recently_canceled?
    canceled_at.present? && canceled_at > 30.hours.ago
  end


  private

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
