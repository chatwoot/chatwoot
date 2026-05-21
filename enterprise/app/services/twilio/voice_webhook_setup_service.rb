class Twilio::VoiceWebhookSetupService
  include Rails.application.routes.url_helpers

  pattr_initialize [:channel!]

  HTTP_METHOD = 'POST'.freeze

  # Returns created TwiML App SID on success.
  def perform
    validate_token_credentials!

    app_sid = create_twiml_app!
    configure_number_webhooks!
    app_sid
  end

  private

  def validate_token_credentials!
    channel.client.incoming_phone_numbers.list(limit: 1)
  rescue StandardError => e
    log_twilio_error('AUTH_VALIDATION_TOKEN', e)
    raise
  end

  def create_twiml_app!
    friendly_name = "Chatwoot Voice #{channel.phone_number}"
    app = channel.client.applications.create(
      friendly_name: friendly_name,
      voice_url: channel.voice_call_webhook_url,
      voice_method: HTTP_METHOD
    )
    app.sid
  rescue StandardError => e
    log_twilio_error('TWIML_APP_CREATE', e)
    raise
  end

  def configure_number_webhooks!
    numbers = channel.client.incoming_phone_numbers.list(phone_number: channel.phone_number)
    if numbers.empty?
      Rails.logger.warn "TWILIO_PHONE_NUMBER_NOT_FOUND: #{channel.phone_number}"
      return
    end

    channel.client
           .incoming_phone_numbers(numbers.first.sid)
           .update(
             voice_url: channel.voice_call_webhook_url,
             voice_method: HTTP_METHOD,
             status_callback: channel.voice_status_webhook_url,
             status_callback_method: HTTP_METHOD
           )
  rescue StandardError => e
    log_twilio_error('NUMBER_WEBHOOKS_UPDATE', e)
    raise
  end

  def log_twilio_error(context, error)
    details = build_error_details(context, error)
    add_twilio_specific_details(details, error)

    backtrace = error.backtrace.is_a?(Array) ? error.backtrace.first(5) : []
    Rails.logger.error("TWILIO_VOICE_SETUP_ERROR: #{details} backtrace=#{backtrace}")
  end

  def build_error_details(context, error)
    {
      context: context,
      phone_number: channel.phone_number,
      account_sid: channel.account_sid,
      error_class: error.class.to_s,
      message: error.message
    }
  end

  def add_twilio_specific_details(details, error)
    details[:status_code] = error.status_code if error.respond_to?(:status_code)
    details[:twilio_code] = error.code if error.respond_to?(:code)
    details[:more_info] = error.more_info if error.respond_to?(:more_info)
    details[:details] = error.details if error.respond_to?(:details)
  end
end
