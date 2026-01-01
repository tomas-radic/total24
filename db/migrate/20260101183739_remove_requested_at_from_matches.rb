class RemoveRequestedAtFromMatches < ActiveRecord::Migration[8.1]
  def up
    remove_column :matches, :requested_at, :datetime
  end

  def down
    add_column :matches, :requested_at, :datetime
    Match.find_each { |match| match.update!(requested_at: match.created_at) }
    change_column_null :matches, :requested_at, false
  end
end
