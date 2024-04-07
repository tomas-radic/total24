class AddCantPlaySinceToPlayers < ActiveRecord::Migration[7.1]
  def change
    add_column :players, :cant_play_since, :datetime
  end
end
