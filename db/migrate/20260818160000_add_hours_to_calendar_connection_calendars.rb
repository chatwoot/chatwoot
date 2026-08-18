class AddHoursToCalendarConnectionCalendars < ActiveRecord::Migration[7.1]
  def change
    add_column :calendar_connection_calendars, :hour_start, :integer, null: false, default: 8
    add_column :calendar_connection_calendars, :hour_end, :integer, null: false, default: 20
  end
end
