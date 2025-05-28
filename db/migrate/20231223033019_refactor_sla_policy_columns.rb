class RefactorSlaPolicyColumns < ActiveRecord::Migration[7.0]
  def change
    rename_column :sla_policies, :rt_threshold, :next_response_time_threshold
    rename_column :sla_policies, :frt_threshold, :first_response_time_threshold
    add_column :sla_policies, :description, :string
    add_column :sla_policies, :resolution_time_threshold, :float
  end
end
