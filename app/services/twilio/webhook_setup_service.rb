class Twilio::WebhookSetupService
  include Rails.application.routes.url_helpers

  pattr_initialize [:inbox!]

  def perform
    if channel.messaging_service_sid?
      update_messaging_service
    else
      update_phone_number
    end
  end

  private

  def update_messaging_service
    twilio_client
      .messaging.services(channel.messaging_service_sid)
      .update(
        inbound_method: 'POST',
        inbound_request_url: twilio_callback_index_url,
        use_inbound_webhook_on_number: false
      )
  end

  def update_phone_number
    if phone_numbers.empty?
      Rails.logger.warn "TWILIO_PHONE_NUMBER_NOT_FOUND: #{channel.phone_number}"
    else
      twilio_client
        .incoming_phone_numbers(phonenumber_sid)
        .update(sms_method: 'POST', sms_url: twilio_callback_index_url)
    end
  end

  def phonenumber_sid
    phone_numbers.first.sid
  end

  def phone_numbers
    @phone_numbers ||= twilio_client.incoming_phone_numbers.list(phone_number: channel.phone_number)
  end

  def channel
    @channel ||= inbox.channel
  end

  def twilio_client
    @twilio_client ||= ::Twilio::REST::Client.new(channel.account_sid, channel.auth_token)
  end
end
