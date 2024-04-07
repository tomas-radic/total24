class AddCancelToMatches < ActiveRecord::Migration[7.1]
  def change
    add_column :matches, :canceled_at, :datetime
    add_reference :matches, :canceled_by, type: :uuid
  end
end
