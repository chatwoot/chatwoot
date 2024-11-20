class UpdateCalBookingJob < ApplicationJob
  queue_as :default

  def perform(booking, booking_uid)
    contact_bookings = ContactBooking.where(booking_uid: booking_uid)

    contact_bookings.update_all(
      host_name: booking[:hostName],
      booking_location: booking[:bookingLocation],
      booking_eventtype: booking[:bookingEventType],
      booking_startTime: booking[:bookingStartTime],
      booking_endTime: booking[:bookingEndTime]
    )
  end
end
