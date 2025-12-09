class AgentNotifications::BookingMailer < ApplicationMailer
  def booking_notification(emails:, conversation:, booking_date:, phone:, email:)
    @conversation = conversation
    @booking_date = booking_date
    @phone = phone
    @customer_email = email
    @platform_name = @conversation&.inbox&.platform_name
    @instagram_profile_url = instagram_profile_url(@conversation)
    subject = 'New booking scheduled 📆'

    mail(to: emails, subject: subject)
  end
end
