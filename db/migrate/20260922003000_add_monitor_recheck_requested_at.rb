class AddMonitorRecheckRequestedAt < ActiveRecord::Migration[7.1]
  def change
    add_column :conversation_monitors, :recheck_requested_at, :datetime
  end
end
