class AddActiveEnrollmentFields < ActiveRecord::Migration[8.1]
  def change
    add_column :enrollments, :rules_accepted_at, :datetime
    add_column :enrollments, :fee_amount_paid, :integer

    Enrollment.find_each do |enr|
      enr.update!(rules_accepted_at: enr.created_at, fee_amount_paid: 0)
    end

    change_column_null :enrollments, :rules_accepted_at, false
  end
end
