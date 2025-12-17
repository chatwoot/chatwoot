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
    Rails.logger.info "[WHATSAPP_SIGNUP] Starting embedded signup for business_id: #{@business_id}, phone_number_id: #{@phone_number_id}"

    validate_parameters!
    Rails.logger.info '[WHATSAPP_SIGNUP] ✓ Parameters validated'

    access_token = exchange_code_for_token
    Rails.logger.info '[WHATSAPP_SIGNUP] ✓ Access token obtained'

    phone_info = fetch_phone_info(access_token)
    Rails.logger.info "[WHATSAPP_SIGNUP] ✓ Phone info fetched: #{phone_info[:phone_number]}"

    validate_token_access(access_token)
    Rails.logger.info '[WHATSAPP_SIGNUP] ✓ Token access validated'

    channel = create_or_reauthorize_channel(access_token, phone_info)
    Rails.logger.info "[WHATSAPP_SIGNUP] ✓ Channel #{@inbox_id.present? ? 'reauthorized' : 'created'}: #{channel.phone_number}"

    channel.setup_webhooks
    Rails.logger.info '[WHATSAPP_SIGNUP] ✓ Webhooks configured'

    check_channel_health_and_prompt_reauth(channel)
    Rails.logger.info '[WHATSAPP_SIGNUP] ✓ Health check completed'

    Rails.logger.info "[WHATSAPP_SIGNUP] ✅ Embedded signup completed successfully for #{channel.phone_number}"
    channel

  rescue StandardError => e
    Rails.logger.error "[WHATSAPP_SIGNUP] Embedded signup failed at step: #{identify_failure_step(e)}"
    Rails.logger.error "[WHATSAPP_SIGNUP] Error: #{e.class.name} - #{e.message}"
    Rails.logger.error "[WHATSAPP_SIGNUP] Backtrace: #{e.backtrace.first(5).join("\n")}"
    raise e
  end

  private

  def exchange_code_for_token
    Whatsapp::TokenExchangeService.new(@code, account: @account).perform
  end

  def fetch_phone_info(access_token)
    Whatsapp::PhoneInfoService.new(@waba_id, @phone_number_id, access_token, account: @account).perform
  end

  def validate_token_access(access_token)
    Whatsapp::TokenValidationService.new(access_token, @waba_id, account: @account).perform
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
    Rails.logger.info "[WHATSAPP_HEALTH] Checking health status for #{channel.phone_number}"

    health_data = Whatsapp::HealthService.new(channel).fetch_health_status
    return unless health_data

    Rails.logger.info "[WHATSAPP_HEALTH] Health data - Platform: #{health_data[:platform_type]}, Throughput: #{health_data.dig(:throughput,
                                                                                                                               'level')}, Status: #{health_data[:name_status]}"

    if channel_in_pending_state?(health_data)
      Rails.logger.warn "[WHATSAPP_HEALTH] ⚠️  Channel #{channel.phone_number} in pending state - marking for reauthorization"
      Rails.logger.warn "[WHATSAPP_HEALTH] Platform Type: #{health_data[:platform_type]}, Throughput Level: #{health_data.dig(:throughput, 'level')}"
      channel.prompt_reauthorization!
    else
      Rails.logger.info "[WHATSAPP_HEALTH] ✓ Channel #{channel.phone_number} health check passed"
    end
  rescue StandardError => e
    Rails.logger.error "[WHATSAPP_HEALTH] Health check failed for channel #{channel.phone_number}: #{e.class.name} - #{e.message}"
    Rails.logger.error "[WHATSAPP_HEALTH] Backtrace: #{e.backtrace.first(3).join("\n")}"
  end

  def channel_in_pending_state?(health_data)
    health_data[:platform_type] == 'NOT_APPLICABLE' ||
      health_data.dig(:throughput, 'level') == 'NOT_APPLICABLE'
  end

  def validate_parameters!
    missing_params = []
    missing_params << 'code' if @code.blank?
    missing_params << 'business_id' if @business_id.blank?
    missing_params << 'waba_id' if @waba_id.blank?

    return if missing_params.empty?

    raise ArgumentError, "Required parameters are missing: #{missing_params.join(', ')}"
  end

  def identify_failure_step(error)
    case error.message
    when /missing/i, /required/i
      'Parameter Validation'
    when /token/i, /code/i, /exchange/i
      'Token Exchange'
    when /phone.*info/i, /fetch/i
      'Phone Info Fetch'
    when /validate.*access/i, /permission/i
      'Token Access Validation'
    when /channel/i, /reauthoriz/i
      'Channel Creation/Reauthorization'
    when /webhook/i
      'Webhook Setup'
    when /health/i
      'Health Check'
    else
      'Unknown Step'
    end
  end
end
