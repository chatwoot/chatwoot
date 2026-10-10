class AddAssignmentPolicyEligibility < ActiveRecord::Migration[7.2]
  def change
    add_column :assignment_policies, :business_hours_only, :boolean, default: false, null: false
    add_reference :assignment_policies, :eligible_custom_role, foreign_key: { to_table: :custom_roles }
  end
end
