class AgentNotifications::BookingMailer < ApplicationMailer

    def booking_notification(agent:, conversation:, booking_date:, phone:, email:)
        @agent = agent
        @conversation = conversation
        @booking_date = booking_date
        @phone = phone
        @customer_email = email
        subject = 'New booking scheduled 📆'
        mail(to: @agent.email, subject: subject)
    end
end