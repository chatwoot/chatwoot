class Whatsapp::WebhookSetupService
  attr_reader :registration_error

  def initialize(channel, waba_id = nil, access_token = nil, is_coexistence: nil)
    @channel = channel
    @waba_id = waba_id || channel.provider_config['business_account_id']
    @access_token = access_token || channel.provider_config['api_key']
    @api_client = Whatsapp::FacebookApiClient.new(@access_token)
    @is_coexistence = is_coexistence
  end

  def perform
    validate_parameters!

    register_phone_number if should_register_phone_number?

    setup_webhook
  end

  def register_callback
    validate_parameters!
    setup_webhook
  end

  private

  # Meta: skip registration for a number that also uses the WhatsApp Business app (@is_coexistence comes from the
  # signup FINISH event). Otherwise register only when needed and Meta confirms the number is not on the app.
  def should_register_phone_number?
    return false if @is_coexistence
    return false unless registration_needed?
    raise 'Could not confirm with Meta whether the number uses the WhatsApp Business app' if health_data[:is_on_biz_app].nil?

    health_data[:is_on_biz_app] == false
  end

  # Re-registering an already registered number succeeds without resetting its PIN, so embedded signup always registers.
  def registration_needed?
    return true if @channel.provider_config['source'] == 'embedded_signup'

    !phone_number_verified? || phone_number_needs_registration?
  end

  def validate_parameters!
    raise ArgumentError, 'Channel is required' if @channel.blank?
    raise ArgumentError, 'WABA ID is required' if @waba_id.blank?
    raise ArgumentError, 'Access token is required' if @access_token.blank?
    raise ArgumentError, 'Phone number ID is required' if @channel.provider_config['phone_number_id'].blank?
  end

  def register_phone_number
    phone_number_id = @channel.provider_config['phone_number_id']
    pin = fetch_or_create_pin

    @api_client.register_phone_number(phone_number_id, pin)
  rescue StandardError => e
    @registration_error = e
    Rails.logger.warn("[WHATSAPP] Phone registration failed but continuing: #{e.message}")
  end

  # Stored before /register so a failure after Meta applies it can't lose it.
  def fetch_or_create_pin
    existing_pin = @channel.provider_config['verification_pin']
    return existing_pin.to_i if existing_pin.present?

    pin = SecureRandom.random_number(900_000) + 100_000
    store_pin(pin)
    pin
  end

  # Skips validation, which re-checks the token against Meta.
  def store_pin(pin)
    @channel.provider_config['verification_pin'] = pin
    @channel.save!(validate: false)
  end

  def setup_webhook
    callback_url = build_callback_url
    verify_token = @channel.provider_config['webhook_verify_token']
    phone_number_id = @channel.provider_config['phone_number_id']

    @api_client.subscribe_phone_number_webhook(@waba_id, phone_number_id, callback_url, verify_token, subscribed_fields: subscribed_fields)
  rescue StandardError => e
    Rails.logger.error("[WHATSAPP] Webhook setup failed: #{e.message}")
    raise "Webhook setup failed: #{e.message}"
  end

  # Subscribe to `calls` only when voice calling is enabled on the inbox
  def subscribed_fields
    fields = %w[messages smb_message_echoes]
    fields << 'calls' if calls_enabled_on_waba?
    fields
  end

  # `subscribed_fields` is a WABA-wide app subscription, so keep `calls` whenever this inbox or
  # any sibling on the same WABA has voice on — otherwise a non-calling sibling's setup would
  # rewrite the shared subscription and drop calls for a calling-enabled sibling.
  def calls_enabled_on_waba?
    return true if @channel.provider_config['calling_enabled']

    Channel::Whatsapp
      .where(provider: 'whatsapp_cloud')
      .where.not(id: @channel.id)
      .where("provider_config->>'business_account_id' = ?", @waba_id)
      .where("provider_config->>'calling_enabled' = 'true'")
      .exists?
  end

  def build_callback_url
    frontend_url = ENV.fetch('FRONTEND_URL', nil)
    phone_number = @channel.phone_number

    "#{frontend_url}/webhooks/whatsapp/#{phone_number}"
  end

  def phone_number_verified?
    phone_number_id = @channel.provider_config['phone_number_id']

    # A connected number is already registered even if its one-time code verification has expired.
    # Otherwise, ownership verification makes it eligible for registration.
    verified = @api_client.phone_number_verified?(phone_number_id)
    Rails.logger.info("[WHATSAPP] Phone number #{phone_number_id} is ready for setup: #{verified}")

    verified
  rescue StandardError => e
    # If verification check fails, assume not verified to be safe
    Rails.logger.error("[WHATSAPP] Phone verification status check failed: #{e.message}")
    false
  end

  # platform_type/throughput_level == 'NOT_APPLICABLE' means the number is still pending provisioning
  def phone_number_needs_registration?
    health_data[:platform_type] == 'NOT_APPLICABLE' ||
      health_data[:throughput_level] == 'NOT_APPLICABLE'
  end

  def health_data
    @health_data ||= Whatsapp::HealthService.new(@channel).fetch_health_status
  rescue StandardError => e
    Rails.logger.error("[WHATSAPP] Health status check failed: #{e.message}")
    {}
  end
end
