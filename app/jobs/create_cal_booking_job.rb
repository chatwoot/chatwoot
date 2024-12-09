class CreateCalBookingJob < ApplicationJob
  queue_as :default

  def perform(account_user_ids, booking)
    account_users = AccountUser.where(id: account_user_ids).includes(:user, :account, account: :contacts)

    account_users.each do |account_user|
      user = account_user.user
      account = account_user.account
      contacts = account.contacts

      contacts.each do |contact|
        next unless contact.email == booking[:bookerEmail] || (contact.phone_number.present? && contact.phone_number == booking[:bookerPhone])

        ContactBooking.create!(
          user_id: user.id,
          account_id: account.id,
          contact_id: contact.id,
          host_name: booking[:hostName],
          booking_location: booking[:bookingLocation],
          booking_eventtype: booking[:bookingEventType],
          booking_startTime: booking[:bookingStartTime],
          booking_endTime: booking[:bookingEndTime],
          booking_uid: booking[:bookingUid]
        )
      end
    end
  end
end
