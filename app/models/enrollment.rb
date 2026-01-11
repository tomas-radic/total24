class Enrollment < ApplicationRecord
  # region Relations
  belongs_to :player
  belongs_to :season
  # endregion Relations

  # region Validations
  validates :player_id, uniqueness: { scope: :season_id }
  # endregion Validations

  # region Scopes
  scope :active, -> { joins(:player)
                        .where(canceled_at: nil)
                        .where.not(rules_accepted_at: nil)
                        .where.not(fee_amount_paid: nil)
                        .merge(Player.active) }
  # endregion Scopes

  def active?
    canceled_at.nil? &&
      rules_accepted_at.present? &&
      fee_amount_paid.present? &&
      player.active?
  end
end
