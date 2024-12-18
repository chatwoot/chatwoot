class ModifyContactBookingsForBookingTimes < ActiveRecord::Migration[7.0]
  def change
    remove_column :contact_bookings, :booking_datetime, :datetime

    add_column :contact_bookings, :booking_startTime, :datetime
    add_column :contact_bookings, :booking_endTime, :datetime
  end
end
