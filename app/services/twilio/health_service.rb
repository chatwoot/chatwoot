class Twilio::HealthService
  include Rails.application.routes.url_helpers

  pattr_initialize [:channel!]

  # Compares the webhooks Twilio actually has against the ones Chatwoot expects.
  # Errors (bad credentials, unknown number) bubble up to the controller as a 422.
  def perform
    webhooks = channel.messaging_service_sid? ? messaging_service_webhooks : phone_number_webhooks

    {
      status: webhooks.all? { |webhook| webhook[:configured] } ? 'healthy' : 'misconfigured',
      webhooks: webhooks
    }
  end

  private

  def messaging_service_webhooks
    service = channel.client.messaging.services(channel.messaging_service_sid).fetch

    [webhook('messaging', twilio_callback_index_url, service.inbound_request_url)]
  end

  def phone_number_webhooks
    number = channel.client.incoming_phone_numbers.list(phone_number: channel.phone_number).first
    raise "Phone number #{channel.phone_number} was not found in the connected Twilio account" if number.nil?

    webhooks = [webhook('messaging', twilio_callback_index_url, number.sms_url)]
    webhooks += voice_webhooks(number) if channel.voice_enabled?
    webhooks
  end

  def voice_webhooks(number)
    [
      webhook('voice', channel.voice_call_webhook_url, number.voice_url),
      webhook('voice_status', channel.voice_status_webhook_url, number.status_callback),
      # Outbound calls dial through the TwiML app, so a stale voice_url here breaks them silently.
      webhook('voice_app', channel.voice_call_webhook_url, twiml_app_voice_url)
    ]
  end

  def twiml_app_voice_url
    return if channel.twiml_app_sid.blank?

    channel.client.applications(channel.twiml_app_sid).fetch.voice_url
  end

  def webhook(name, expected, actual)
    { name: name, expected: expected, actual: actual.presence, configured: expected == actual }
  end
end
