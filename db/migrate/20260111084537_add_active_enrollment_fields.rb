class AddActiveEnrollmentFields < ActiveRecord::Migration[8.1]
  def change
    add_column :enrollments, :rules_accepted_at, :datetime
    add_column :enrollments, :fee_amount_paid, :integer
  end
end
