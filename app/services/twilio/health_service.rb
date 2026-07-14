class Twilio::HealthService
  include Rails.application.routes.url_helpers

  pattr_initialize [:channel!]

  # Our Twilio routes are POST-only, so a matching URL on the wrong HTTP method never reaches us.
  HTTP_METHOD = 'POST'.freeze

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
    # With use_inbound_webhook_on_number set, Twilio prefers the number's webhook over ours.
    configured = service.inbound_method == HTTP_METHOD && !service.use_inbound_webhook_on_number

    [webhook('messaging', twilio_callback_index_url, service.inbound_request_url, extra: configured)]
  end

  def phone_number_webhooks
    number = channel.client.incoming_phone_numbers.list(phone_number: channel.phone_number).first
    raise "Phone number #{channel.phone_number} was not found in the connected Twilio account" if number.nil?

    webhooks = [webhook('messaging', twilio_callback_index_url, number.sms_url, extra: number.sms_method == HTTP_METHOD)]
    webhooks += voice_webhooks(number) if channel.voice_enabled?
    webhooks
  end

  def voice_webhooks(number)
    [
      webhook('voice', channel.voice_call_webhook_url, number.voice_url, extra: number.voice_method == HTTP_METHOD),
      webhook('voice_status', channel.voice_status_webhook_url, number.status_callback,
              extra: number.status_callback_method == HTTP_METHOD),
      # Outbound calls dial through the TwiML app, so a stale voice_url here breaks them silently.
      twiml_app_webhook
    ]
  end

  def twiml_app_webhook
    return webhook('voice_app', channel.voice_call_webhook_url, nil) if channel.twiml_app_sid.blank?

    app = channel.client.applications(channel.twiml_app_sid).fetch
    webhook('voice_app', channel.voice_call_webhook_url, app.voice_url, extra: app.voice_method == HTTP_METHOD)
  end

  def webhook(name, expected, actual, extra: false)
    { name: name, expected: expected, actual: actual.presence, configured: expected == actual && extra }
  end
end
