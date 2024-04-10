class RenameEventsToReportEvents < ActiveRecord::Migration[6.0]
  def change
    rename_table :events, :reporting_events
  end
end
