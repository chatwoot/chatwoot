class RefactorSlaPolicyColumns < ActiveRecord::Migration[7.0]
  def change
    if column_exists?(:sla_policies, :rt_threshold) && !column_exists?(:sla_policies, :next_response_time_threshold)
      rename_column :sla_policies, :rt_threshold, :next_response_time_threshold
    end
    if column_exists?(:sla_policies, :frt_threshold) && !column_exists?(:sla_policies, :first_response_time_threshold)
      rename_column :sla_policies, :frt_threshold, :first_response_time_threshold
    end
    add_column :sla_policies, :description, :string, if_not_exists: true
    add_column :sla_policies, :resolution_time_threshold, :float, if_not_exists: true
  end
end
