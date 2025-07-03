class RemoveAccessDeniedSince < ActiveRecord::Migration[8.0]
  def change
    remove_column :players, :access_denied_since, :datetime
    remove_column :managers, :access_denied_since, :datetime
  end
end
