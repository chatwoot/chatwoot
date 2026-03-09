class ChangeAppliedSlaSlaStatusToEnum < ActiveRecord::Migration[7.0]
  def change
    remove_column :applied_slas, :sla_status, :string
    add_column :applied_slas, :sla_status, :integer, default: 0
  end
end
