class RemovePerformancePlayerTagLabel < ActiveRecord::Migration[8.1]
  def change
    remove_column :seasons, :performance_player_tag_label, :string, null: false, default: "reg"
  end
end
