class RenameRtThresholdToTrtSlaPolicy < ActiveRecord::Migration[7.0]
  def change
    rename column :sla_policies, :rt_threshold, :next_response_time
    rename column :sla_policies, :frt_threshold, :first_response_time
  end
end
