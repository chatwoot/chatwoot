class Whatsapp::WebhookSetupService
  def initialize(channel, waba_id, access_token)
    @channel = channel
    @waba_id = waba_id
    @access_token = access_token
    @api_client = Whatsapp::FacebookApiClient.new(access_token)
  end

  def perform
    validate_parameters!
    # Since coexistence method does not need to register, we check it
    register_phone_number unless phone_number_verified?
    setup_webhook
  end

  private

  def validate_parameters!
    raise ArgumentError, 'Channel is required' if @channel.blank?
    raise ArgumentError, 'WABA ID is required' if @waba_id.blank?
    raise ArgumentError, 'Access token is required' if @access_token.blank?
  end

  def register_phone_number
    phone_number_id = @channel.provider_config['phone_number_id']
    pin = fetch_or_create_pin

    @api_client.register_phone_number(phone_number_id, pin)
    store_pin(pin)
  rescue StandardError => e
    Rails.logger.warn("[WHATSAPP] Phone registration failed but continuing: #{e.message}")
    # Continue with webhook setup even if registration fails
    # This is just a warning, not a blocking error
  end

  def fetch_or_create_pin
    # Check if we have a stored PIN for this phone number
    existing_pin = @channel.provider_config['verification_pin']
    return existing_pin.to_i if existing_pin.present?

    # Generate a new 6-digit PIN if none exists
    SecureRandom.random_number(900_000) + 100_000
  end

  def store_pin(pin)
    # Store the PIN in provider_config for future use
    @channel.provider_config['verification_pin'] = pin
    @channel.save!
  end

  def setup_webhook
    callback_url = build_callback_url
    verify_token = @channel.provider_config['webhook_verify_token']

    @api_client.subscribe_waba_webhook(@waba_id, callback_url, verify_token)

  rescue StandardError => e
    Rails.logger.error("[WHATSAPP] Webhook setup failed: #{e.message}")
    raise "Webhook setup failed: #{e.message}"
  end

  def build_callback_url
    frontend_url = ENV.fetch('FRONTEND_URL', nil)
    phone_number = @channel.phone_number

    "#{frontend_url}/webhooks/whatsapp/#{phone_number}"
  end

  def phone_number_verified?
    phone_number_id = @channel.provider_config['phone_number_id']

    @api_client.phone_number_verified?(phone_number_id)
  rescue StandardError => e
    Rails.logger.error("[WHATSAPP] Phone registration status check failed, but continuing: #{e.message}")
    false
  end
end
