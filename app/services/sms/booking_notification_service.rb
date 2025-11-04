class Sms::BookingNotificationService
  def initialize(conversation:, booking_date:, phone:, email:)
    @conversation = conversation
    @account = conversation.account
    @booking_date = booking_date
    @customer_phone = phone
    @customer_email = email
  end

  def perform
    return unless sms_config_enabled?

    recipients = recipients_with_phone_numbers
    return if recipients.blank?

    message_body = build_message_body
    send_sms_to_recipients(recipients, message_body)
  rescue StandardError => e
    Rails.logger.error("Failed to send booking SMS notifications: #{e.message}")
  end

  private

  def sms_config_enabled?
    twilio_account_sid.present? &&
      twilio_auth_token.present? &&
      organization_phone_number.present?
  end

  def twilio_account_sid
    @twilio_account_sid ||= GlobalConfig.get_value('TWILIO_ACCOUNT_SID')
  end

  def twilio_auth_token
    @twilio_auth_token ||= GlobalConfig.get_value('TWILIO_AUTH_TOKEN')
  end

  def organization_phone_number
    @organization_phone_number ||= GlobalConfig.get_value('TWILIO_ORGANIZATION_PHONE_NUMBER')
  end

  def recipients_with_phone_numbers
    # Get all agents and administrators with phone numbers
    # Include both User and SuperAdmin types (STI)
    User.unscoped
        .joins(:account_users)
        .where(account_users: { account_id: @account.id })
        .where(account_users: { role: [
                 AccountUser.roles[:agent],
                 AccountUser.roles[:administrator]
               ] })
        .where.not(phone_number: [nil, ''])
        .group('users.id')
  end

  def build_message_body
    account_name = @account.name
    conversation_url = Rails.application.routes.url_helpers.app_account_conversation_url(
      account_id: @account.id,
      id: @conversation.id,
      host: ENV.fetch('FRONTEND_URL', 'http://localhost:3000')
    )

    <<~SMS
      📆 New Booking Scheduled

      Dealership: #{account_name}

      Booking Date: #{@booking_date}
      Customer Phone: #{@customer_phone}
      Customer Email: #{@customer_email}

      View conversation: #{conversation_url}
    SMS
  end

  def send_sms_to_recipients(recipients, message_body)
    twilio_client = Twilio::REST::Client.new(twilio_account_sid, twilio_auth_token)

    recipients.each do |recipient|
      twilio_client.messages.create(
        from: organization_phone_number,
        to: recipient.phone_number,
        body: message_body
      )
    rescue Twilio::REST::TwilioError => e
      Rails.logger.error("Failed to send booking SMS to #{recipient.name} (#{recipient.phone_number}): #{e.message}")
    rescue StandardError => e
      Rails.logger.error("Unexpected error sending booking SMS to #{recipient.name}: #{e.message}")
    end
  end
end
