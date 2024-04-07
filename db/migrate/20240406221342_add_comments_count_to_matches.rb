class AddCommentsCountToMatches < ActiveRecord::Migration[7.1]
  def change
    add_column :matches, :comments_count, :integer, null: false, default: 0
  end
end
