class AddAccountRefToContactBooking < ActiveRecord::Migration[7.0]
  def change
    add_reference :contact_bookings, :account, null: false, foreign_key: true
  end
end
