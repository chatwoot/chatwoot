class Twilio::HealthService
  include Rails.application.routes.url_helpers

  pattr_initialize [:channel!]

  # Our Twilio routes are POST-only, so a matching URL on the wrong HTTP method never reaches us.
  HTTP_METHOD = 'POST'.freeze

  # Reports what Twilio actually has configured against what Chatwoot expects, so a number that
  # looks connected but silently drops traffic (wrong method, trunk, foreign TwiML app) is visible.
  # Errors (bad credentials, unknown number) bubble up to the controller as a 422.
  def perform
    webhooks = channel.messaging_service_sid? ? messaging_service_webhooks : phone_number_webhooks
    account = account_details
    sender = sender_details

    {
      status: healthy?(account, sender, webhooks) ? 'healthy' : 'misconfigured',
      account: account,
      sender: sender,
      voice_enabled: channel.voice_enabled?,
      webhooks: webhooks
    }
  end

  private

  # Correct webhooks are not enough: a suspended account or a number missing a capability the inbox
  # needs still drops traffic, and reporting that as healthy contradicts the details rendered beside it.
  def healthy?(account, sender, webhooks)
    webhooks.all? { |webhook| webhook[:configured] } && account_usable?(account) && capabilities_present?(sender)
  end

  # Restricted API keys cannot read the account at all, which is not itself a health problem.
  def account_usable?(account)
    account.nil? || account[:status].to_s.casecmp?('active')
  end

  def capabilities_present?(sender)
    return true unless sender[:type] == 'phone_number'

    required_capabilities.all? { |capability| sender[:capabilities][capability] }
  end

  def required_capabilities
    channel.voice_enabled? ? %w[sms voice] : %w[sms]
  end

  # Restricted API keys can read numbers and applications but not the Account resource, so this is
  # supplementary context only — the webhook checks below are the real health signal and still fail loudly.
  def account_details
    account = channel.client.api.accounts(channel.account_sid).fetch
    { sid: account.sid, friendly_name: account.friendly_name, status: account.status, type: account.type }
  rescue Twilio::REST::RestError
    nil
  end

  def sender_details
    return messaging_service_details if channel.messaging_service_sid?

    {
      type: 'phone_number',
      sid: number.sid,
      label: number.phone_number,
      friendly_name: number.friendly_name,
      # Twilio returns these capitalised in its docs but lowercased over the wire.
      capabilities: (number.capabilities || {}).transform_keys { |key| key.to_s.downcase }
    }
  end

  def messaging_service_details
    { type: 'messaging_service', sid: messaging_service.sid, label: messaging_service.friendly_name }
  end

  def messaging_service
    @messaging_service ||= channel.client.messaging.services(channel.messaging_service_sid).fetch
  end

  def number
    return @number if @number

    @number = channel.client.incoming_phone_numbers.list(phone_number: channel.phone_number).first
    raise "Phone number #{channel.phone_number} was not found in the connected Twilio account" if @number.nil?

    @number
  end

  def messaging_service_webhooks
    # With use_inbound_webhook_on_number set, Twilio prefers the number's webhook over ours.
    override = 'overridden_by_number' if messaging_service.use_inbound_webhook_on_number

    [webhook('messaging', twilio_callback_index_url, messaging_service.inbound_request_url,
             method: messaging_service.inbound_method, override: override)]
  end

  def phone_number_webhooks
    # An sms_application_sid on the number makes Twilio ignore sms_url entirely.
    override = 'overridden_by_application' if number.sms_application_sid.present?
    webhooks = [webhook('messaging', twilio_callback_index_url, number.sms_url, method: number.sms_method, override: override)]
    webhooks += voice_webhooks if channel.voice_enabled?
    webhooks
  end

  def voice_webhooks
    [
      webhook('voice', channel.voice_call_webhook_url, number.voice_url, method: number.voice_method, override: voice_override),
      webhook('voice_status', channel.voice_status_webhook_url, number.status_callback, method: number.status_callback_method),
      # Outbound calls dial through the TwiML app, so a stale voice_url here breaks them silently.
      twiml_app_webhook
    ]
  end

  # A trunk or a foreign TwiML app on the number makes Twilio ignore voice_url entirely.
  def voice_override
    return 'overridden_by_trunk' if number.trunk_sid.present?
    return 'overridden_by_application' if number.voice_application_sid.present? && number.voice_application_sid != channel.twiml_app_sid

    nil
  end

  def twiml_app_webhook
    return missing_twiml_app_webhook if channel.twiml_app_sid.blank?

    app = channel.client.applications(channel.twiml_app_sid).fetch
    webhook('voice_app', channel.voice_call_webhook_url, app.voice_url, method: app.voice_method)
  rescue Twilio::REST::RestError => e
    raise unless e.status_code == 404

    # The stored app was deleted in Twilio; repair recreates it.
    missing_twiml_app_webhook
  end

  def missing_twiml_app_webhook
    webhook('voice_app', channel.voice_call_webhook_url, nil, override: 'missing_twiml_app')
  end

  def webhook(name, expected, actual, method: nil, override: nil)
    actual = actual.presence
    reason = webhook_reason(expected, actual, method, override)

    { name: name, expected: expected, actual: actual, method: method, configured: reason.nil?, reason: reason }
  end

  def webhook_reason(expected, actual, method, override)
    return override if override
    return 'not_set' if actual.blank?
    return 'url_mismatch' if actual != expected
    return 'wrong_http_method' if method != HTTP_METHOD

    nil
  end
end
