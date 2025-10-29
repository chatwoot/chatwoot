class Whatsapp::EmbeddedSignupService
  def initialize(account:, params:, inbox_id: nil)
    @account = account
    @code = params[:code]
    @business_id = params[:business_id]
    @waba_id = params[:waba_id]
    @phone_number_id = params[:phone_number_id]
    @inbox_id = inbox_id
  end

  def perform
    validate_parameters!

    access_token = exchange_code_for_token
    phone_info = fetch_phone_info(access_token)
    validate_token_access(access_token)

    channel = create_or_reauthorize_channel(access_token, phone_info)
    channel.setup_webhooks

    # Only check health for reauthorization, not for new channel creation
    # New channels often have NOT_APPLICABLE status during initial setup
    check_channel_health_and_prompt_reauth(channel) if @inbox_id.present?

    channel

  rescue StandardError => e
    Rails.logger.error("[WHATSAPP] Embedded signup failed: #{e.message}")
    raise e
  end

  private

  def exchange_code_for_token
    Whatsapp::TokenExchangeService.new(@code).perform
  end

  def fetch_phone_info(access_token)
    Whatsapp::PhoneInfoService.new(@waba_id, @phone_number_id, access_token).perform
  end

  def validate_token_access(access_token)
    Whatsapp::TokenValidationService.new(access_token, @waba_id).perform
  end

  def create_or_reauthorize_channel(access_token, phone_info)
    if @inbox_id.present?
      Whatsapp::ReauthorizationService.new(
        account: @account,
        inbox_id: @inbox_id,
        phone_number_id: @phone_number_id,
        business_id: @business_id
      ).perform(access_token, phone_info)
    else
      waba_info = { waba_id: @waba_id, business_name: phone_info[:business_name] }
      Whatsapp::ChannelCreationService.new(@account, waba_info, phone_info, access_token).perform
    end
  end

  def check_channel_health_and_prompt_reauth(channel)
    health_data = Whatsapp::HealthService.new(channel).fetch_health_status
    return unless health_data

    # Check for actual error conditions, not just pending states
    # NOT_APPLICABLE is normal for newly onboarded accounts
    if channel_has_critical_issues?(health_data)
      Rails.logger.warn "[WHATSAPP] Channel #{channel.phone_number} has critical issues, prompting reauthorization"
      channel.prompt_reauthorization!
    else
      Rails.logger.info "[WHATSAPP] Channel #{channel.phone_number} health check passed"
    end
  rescue StandardError => e
    Rails.logger.error "[WHATSAPP] Health check failed for channel #{channel.phone_number}: #{e.message}"
  end

  def channel_has_critical_issues?(health_data)
    # Only prompt reauth for actual error conditions, not pending states
    # quality_rating: RED or YELLOW indicates issues
    # account_mode: SANDBOX might need attention
    # code_verification_status: VERIFIED is good, anything else might be an issue

    quality_rating = health_data[:quality_rating]
    account_mode = health_data[:account_mode]

    # Critical issues that require reauthorization
    quality_rating == 'RED' ||
      (account_mode && account_mode != 'LIVE' && account_mode != 'SANDBOX')
  end

  def validate_parameters!
    missing_params = []
    missing_params << 'code' if @code.blank?
    missing_params << 'business_id' if @business_id.blank?
    missing_params << 'waba_id' if @waba_id.blank?

    return if missing_params.empty?

    raise ArgumentError, "Required parameters are missing: #{missing_params.join(', ')}"
  end
end
