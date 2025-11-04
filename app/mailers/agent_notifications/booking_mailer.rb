class AgentNotifications::BookingMailer < ApplicationMailer
  def booking_notification(emails:, conversation:, booking_date:, phone:, email:)
    @conversation = conversation
    @booking_date = booking_date
    @phone = phone
    @customer_email = email
    @platform_name = @conversation&.inbox&.platform_name
    subject = 'New booking scheduled 📆'

    mail(to: emails, subject: subject)
  end
end
