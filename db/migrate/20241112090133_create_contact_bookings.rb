class CreateContactBookings < ActiveRecord::Migration[7.0]
  def change
    create_table :contact_bookings do |t|
      t.references :user, null: false, foreign_key: true
      t.references :contact, null: false, foreign_key: true
      t.string :host_name
      t.string :booking_location
      t.datetime :booking_datetime
      t.string :booking_eventtype

      t.timestamps
    end
  end
end
