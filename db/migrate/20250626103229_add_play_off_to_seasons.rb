class AddPlayOffToSeasons < ActiveRecord::Migration[8.0]
  def change
    add_column :seasons, :performance_play_off_size, :integer, null: false, default: 4
    add_column :seasons, :regular_a_play_off_size, :integer, null: false, default: 8
    add_column :seasons, :regular_b_play_off_size, :integer, null: false, default: 16
    add_column :seasons, :performance_player_tag_label, :string, null: false, default: "reg."
    add_column :seasons, :play_off_min_matches_count, :integer, null: false, default: 10
    add_column :seasons, :play_off_conditions, :text
  end
end
