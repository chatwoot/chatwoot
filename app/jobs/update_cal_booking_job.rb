class UpdateCalBookingJob < ApplicationJob
  queue_as :default

  def perform(booking)
    contact_bookings = ContactBooking.where(booking_uid: booking[:originalBookingUid])

    contact_bookings.update_all(
      host_name: booking[:hostName],
      booking_location: booking[:bookingLocation],
      booking_eventtype: booking[:bookingEventType],
      booking_startTime: booking[:bookingStartTime],
      booking_endTime: booking[:bookingEndTime],
      booking_uid: booking[:bookingUid]
    )
  end
end
