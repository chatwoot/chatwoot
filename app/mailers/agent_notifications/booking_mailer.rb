class AgentNotifications::BookingMailer < ApplicationMailer
  def booking_notification(agents:, conversation:, booking_date:, phone:, email:)
    @agents = agents
    @conversation = conversation
    @booking_date = booking_date
    @phone = phone
    @customer_email = email
    @platform_name = @conversation&.inbox&.platform_name
    subject = 'New booking scheduled 📆'

    recipient_emails = @agents.map(&:email)
    mail(to: recipient_emails, subject: subject)
  end
end
