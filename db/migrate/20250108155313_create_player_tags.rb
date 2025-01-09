class CreatePlayerTags < ActiveRecord::Migration[8.0]
  def change
    create_table :player_tags, id: :uuid do |t|
      t.references :player, null: false, foreign_key: true, type: :uuid
      t.references :tag, null: false, foreign_key: true, type: :uuid

      t.timestamps
    end

    add_index :player_tags, [:player_id, :tag_id], unique: true
  end
end
