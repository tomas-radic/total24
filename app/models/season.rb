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
  validates :name, :performance_play_off_size,
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

end
