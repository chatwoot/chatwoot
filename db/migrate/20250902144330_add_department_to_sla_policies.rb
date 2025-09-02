class AddDepartmentToSlaPolicies < ActiveRecord::Migration[7.0]
  def change
    add_reference :sla_policies, :department, null: true, foreign_key: true
    add_index :sla_policies, :department_id
  end
end