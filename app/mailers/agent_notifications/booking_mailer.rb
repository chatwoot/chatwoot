class AgentNotifications::BookingMailer < ApplicationMailer
  def booking_notification(emails:, conversation:, booking_date:, phone:, email:)
    @conversation = conversation
    @account = conversation.account
    ensure_current_account(@account)
    
    # If account is suspended, send to SuperAdmins only
    recipients = if @account.suspended?
                   super_admin_emails(@account)
                 else
                   emails
                 end
    
    return if recipients.blank?

    @booking_date = booking_date
    @phone = phone
    @customer_email = email
    @platform_name = @conversation&.inbox&.platform_name
    @instagram_profile_url = instagram_profile_url(@conversation)
    subject = 'New booking scheduled 📆'

    mail(to: recipients, subject: subject)
  end
end
