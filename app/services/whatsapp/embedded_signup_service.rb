class Whatsapp::EmbeddedSignupService
  def initialize(account:, code:, business_id:, waba_id:, phone_number_id:)
    @account = account
    @code = code
    @business_id = business_id
    @waba_id = waba_id
    @phone_number_id = phone_number_id
  end

  def perform
    validate_parameters!

    # Exchange code for user access token
    access_token = Whatsapp::TokenExchangeService.new(@code).perform

    # Fetch phone information
    phone_info = Whatsapp::PhoneInfoService.new(@waba_id, @phone_number_id, access_token).perform

    # Validate token has access to the WABA
    Whatsapp::TokenValidationService.new(access_token, @waba_id).perform

    # Create channel
    waba_info = { waba_id: @waba_id, business_name: phone_info[:business_name] }

    # Webhook setup is now handled in the channel after_create_commit callback
    Whatsapp::ChannelCreationService.new(@account, waba_info, phone_info, access_token).perform
  rescue StandardError => e
    Rails.logger.error("[WHATSAPP] Embedded signup failed: #{e.message}")
    raise e
  end

  def perform_reauthorization
    validate_reauthorization_params!
    channel = find_and_validate_channel

    GlobalConfig.clear_cache
    access_token = exchange_code_for_token
    phone_info = fetch_phone_info_via_waba(@waba_id, @phone_number_id, access_token)
    validate_token_waba_access(access_token, @waba_id)

    update_channel_for_reauthorization(channel, phone_info, access_token)
    register_phone_number(phone_info[:phone_number_id], access_token)
    override_waba_webhook(@waba_id, channel, access_token)

    channel
  rescue StandardError => e
    Rails.logger.error("[WHATSAPP] Reauthorization failed: #{e.message}")
    raise e
  end

  private

  def validate_parameters!
    missing_params = []
    missing_params << 'code' if @code.blank?
    missing_params << 'business_id' if @business_id.blank?
    missing_params << 'waba_id' if @waba_id.blank?

    return if missing_params.empty?

    raise ArgumentError, "Required parameters are missing: #{missing_params.join(', ')}"
  end
end
