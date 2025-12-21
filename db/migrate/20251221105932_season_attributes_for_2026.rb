class SeasonAttributesFor2026 < ActiveRecord::Migration[8.1]
  def change
    remove_column :seasons, :play_off_size, :integer
    remove_column :seasons, :points_single_02, :integer
    remove_column :seasons, :points_single_12, :integer
    remove_column :seasons, :points_single_21, :integer
    remove_column :seasons, :points_single_20, :integer
    remove_column :seasons, :points_double_02, :integer
    remove_column :seasons, :points_double_12, :integer
    remove_column :seasons, :points_double_21, :integer
    remove_column :seasons, :points_double_20, :integer

    add_column :seasons, :max_matches_with_opponent, :integer, null: false, default: 2
    add_column :seasons, :max_pending_matches, :integer, null: false, default: 3
  end
end
