class PlayerTag < ApplicationRecord
  belongs_to :player
  belongs_to :tag

  validates :tag_id, presence: true, uniqueness: { scope: :player_id }
  validates :player_id, presence: true
end
