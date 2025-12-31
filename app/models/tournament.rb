class Tournament < ApplicationRecord
  include ColorBase
  include Reactions

  before_validation :set_random_color_base


  # region Relations
  belongs_to :season
  belongs_to :place, optional: true
  has_many :noticed_events, as: :record, dependent: :destroy, class_name: "Noticed::Event"
  has_many :notifications, through: :noticed_events, class_name: "Noticed::Notification"
  # endregion Relations

  # region Validations
  validates :name, :main_info, :color_base,
            presence: true
  validates :begin_date, :end_date,
            presence: true, if: Proc.new { |t| t.published? }
  validates :end_date, comparison: { greater_than_or_equal_to: :begin_date }, allow_blank: true
  # endregion Validations

  # region Scopes
  scope :published, -> { where.not(published_at: nil) }
  scope :sorted, -> { order(begin_date: :desc, updated_at: :desc) }
  # endregion Scopes

  def published?
    published_at.present?
  end
end
