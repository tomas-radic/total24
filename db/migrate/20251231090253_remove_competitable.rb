class RemoveCompetitable < ActiveRecord::Migration[8.1]
  def up
    add_reference :matches, :season, type: :uuid, foreign_key: true

    Match.find_each do |match|
      match.update!(season_id: match.competitable_id)
    end

    change_column_null :matches, :season_id, false

    remove_index :matches, [:competitable_type, :competitable_id]
    remove_column :matches, :competitable_type, :string
    remove_column :matches, :competitable_id, :uuid
  end

  def down
    add_reference :matches, :competitable,
                  type: :uuid, polymorphic: true, index: true

    Match.find_each do |match|
      match.update!(competitable_id: match.season_id, competitable_type: "Season")
    end

    change_column_null :matches, :competitable_id, false
    change_column_null :matches, :competitable_type, false

    remove_index :matches, :season_id
    remove_column :matches, :season_id, :uuid
  end
end
