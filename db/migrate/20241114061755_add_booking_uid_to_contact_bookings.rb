class AddBookingUidToContactBookings < ActiveRecord::Migration[7.0]
  def change
    add_column :contact_bookings, :booking_uid, :string
  end
end
