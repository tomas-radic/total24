class AddReactionsCountToMatches < ActiveRecord::Migration[7.1]
  def change
    add_column :matches, :reactions_count, :integer, null: false, default: 0
  end
end
