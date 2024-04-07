class AddPredictionsDisabledSinceToMatches < ActiveRecord::Migration[7.1]
  def change
    add_column :matches, :predictions_disabled_since, :datetime
  end
end
