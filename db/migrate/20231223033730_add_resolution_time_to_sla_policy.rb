class AddResolutionTimeToSlaPolicy < ActiveRecord::Migration[7.0]
  def change
    add_column :sla_policies, :resolution_time_threshold, :float
  end
end
