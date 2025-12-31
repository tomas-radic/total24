class RemoveRankingCountedFromMatches < ActiveRecord::Migration[8.1]
  def change
    remove_column :matches, :ranking_counted, :boolean, null: false, default: true
  end
end
