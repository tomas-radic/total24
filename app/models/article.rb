class Article < ApplicationRecord
  include ColorBase
  include Reactions

  # region Scopes
  scope :published, -> { where.not(published_at: nil) }
  scope :sorted, -> { order(created_at: :desc) }
  # endregion Scopes

  # region Validations
  validates :title, :content, :color_base,
            presence: true
  # endregion Validations

  # region Relations
  belongs_to :manager
  belongs_to :season
  # endregion Relations


  def published?
    published_at.present?
  end
end
