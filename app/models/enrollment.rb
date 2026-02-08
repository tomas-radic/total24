class Enrollment < ApplicationRecord
  # region Relations
  belongs_to :player
  belongs_to :season
  # endregion Relations

  # region Validations
  validates :player_id, uniqueness: { scope: :season_id }
  validates :rules_accepted_at, presence: true
  # endregion Validations

  # region Scopes
  scope :active, -> { joins(:player)
                        .where(canceled_at: nil)
                        .where.not(fee_amount_paid: nil)
                        .where.not(rules_accepted_at: nil)
                        .merge(Player.active) }
  # endregion Scopes

  def active?
    canceled_at.nil? &&
      fee_amount_paid.present? &&
      rules_accepted_at.present? &&
      player.active?
  end

  def canceled?
    canceled_at.present?
  end
end
