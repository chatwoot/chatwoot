class AddAssignmentEligibleToInboxMembers < ActiveRecord::Migration[7.0]
  def change
    add_column :inbox_members, :assignment_eligible, :boolean, default: true, null: false
  end
end
