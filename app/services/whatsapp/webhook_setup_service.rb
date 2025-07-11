class Whatsapp::WebhookSetupService
  def initialize(channel, waba_id, access_token)
    @channel = channel
    @waba_id = waba_id
    @access_token = access_token
    @api_client = Whatsapp::FacebookApiClient.new(access_token)
  end

  def perform
    validate_parameters!
    register_phone_number
    setup_webhook
  end

  private

  def validate_parameters!
    raise ArgumentError, 'Channel is required' if @channel.blank?
    raise ArgumentError, 'WABA ID is required' if @waba_id.blank?
    raise ArgumentError, 'Access token is required' if @access_token.blank?
  end

  def register_phone_number
    # Generate a random 6-digit PIN
    pin = SecureRandom.random_number(900_000) + 100_000
    phone_number_id = @channel.provider_config['phone_number_id']

    @api_client.register_phone_number(phone_number_id, pin)
  rescue StandardError => e
    Rails.logger.error("[WHATSAPP] Phone registration failed: #{e.message}")
    # Continue with webhook setup even if registration fails
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
end