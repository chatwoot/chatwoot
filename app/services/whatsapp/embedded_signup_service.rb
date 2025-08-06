class Whatsapp::EmbeddedSignupService
  def initialize(account:, code:, business_id:, waba_id:, phone_number_id:, is_business_app_onboarding: false)
    @account = account
    @code = code
    @business_id = business_id
    @waba_id = waba_id
    @phone_number_id = phone_number_id
    @is_business_app_onboarding = is_business_app_onboarding
  end

  def perform
    validate_parameters!

    # Exchange code for user access token
    access_token = Whatsapp::TokenExchangeService.new(@code).perform

    # Fetch phone information
    phone_info = Whatsapp::PhoneInfoService.new(@waba_id, @phone_number_id, access_token).perform

    # Validate token has access to the WABA
    Whatsapp::TokenValidationService.new(access_token, @waba_id).perform

    # Build WABA info for channel creation
    waba_info = { waba_id: @waba_id, business_name: phone_info[:business_name] }

    # Create channel (with business-app onboarding flag)
    channel = Whatsapp::ChannelCreationService.new(
      @account,
      waba_info,
      phone_info,
      access_token,
      is_business_app_onboarding: @is_business_app_onboarding
    ).perform

    enable_sync_features(channel, access_token) if channel && @is_business_app_onboarding

    channel
  rescue StandardError => e
    Rails.logger.error("[WHATSAPP] Embedded signup failed: #{e.message}")
    raise e
  end

  private

  def validate_parameters!
    missing_params = []
    missing_params << 'code' if @code.blank?
    missing_params << 'business_id' if @business_id.blank?
    missing_params << 'waba_id' if @waba_id.blank?
    missing_params << 'is_business_app_onboarding' if @is_business_app_onboarding.blank?

    return if missing_params.empty?

    raise ArgumentError, "Required parameters are missing: #{missing_params.join(', ')}"
  end

  def enable_sync_features(channel, access_token)
    client   = Whatsapp::FacebookApiClient.new(access_token)
    phone_id = channel.provider_config['phone_number_id']

    Rails.logger.info("[WHATSAPP] Initiating contact sync for channel #{channel.id}")
    client.request_state_sync(phone_id)

    Rails.logger.info("[WHATSAPP] Initiating conversation history sync for channel #{channel.id}")
    client.request_history_sync(phone_id)
  end
end
