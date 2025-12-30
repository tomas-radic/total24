class RemovePlayersNameUniqueness < ActiveRecord::Migration[8.1]
  def change
    remove_index :players, :name
  end
end
