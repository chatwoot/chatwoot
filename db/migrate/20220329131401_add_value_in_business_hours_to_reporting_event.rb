class AddValueInBusinessHoursToReportingEvent < ActiveRecord::Migration[6.1]
  def change
    change_table :reporting_events, bulk: true do |t|
      t.float :value_in_business_hours, default: nil
      t.datetime :event_start_time, default: nil
      t.datetime :event_end_time, default: nil
    end
  end
end
