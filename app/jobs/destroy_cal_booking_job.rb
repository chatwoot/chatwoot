class DestroyCalBookingJob < ApplicationJob
  queue_as :default

  def perform(booking_uids)
    contact_bookings = ContactBooking.where(booking_uid: booking_uids)

    contact_bookings.destroy_all
  end
end
