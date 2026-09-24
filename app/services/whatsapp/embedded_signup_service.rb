class Whatsapp::EmbeddedSignupService
  def initialize(account:, params:, inbox_id: nil)
    @account = account
    @code = params[:code]
    @waba_id = params[:waba_id]
    @phone_number_id = params[:phone_number_id]
    @inbox_id = inbox_id
    @is_coexistence = ActiveModel::Type::Boolean.new.cast(params[:is_coexistence])
  end

  def perform
    validate_parameters!

    access_token = exchange_code_for_token
    phone_info = fetch_phone_info(access_token)

    channel = create_or_reauthorize_channel(access_token, phone_info)
    # NOTE: We call setup_webhooks explicitly here instead of relying on after_commit callback because:
    # 1. Reauthorization flow updates an existing channel (not a create), so after_commit on: :create won't trigger
    # 2. We need to run check_channel_health_and_prompt_reauth after webhook setup completes
    # 3. The channel is marked with source: 'embedded_signup' to skip the after_commit callback
    channel.setup_webhooks(is_coexistence: @is_coexistence)
    # Skip health check on reauth (avoids false disconnect emails) and on coexistence signups
    # (Meta's health data can lag several minutes behind a fresh FINISH event).
    check_channel_health_and_prompt_reauth(channel) if @inbox_id.blank? && !@is_coexistence
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
    Whatsapp::PhoneInfoService.new(
      @waba_id, @phone_number_id, access_token, expected_phone_number: reauthorizing_channel&.phone_number
    ).perform
  end

  # When phone_number_id is omitted (coexistence completions can leave it blank), this lets
  # PhoneInfoService match the WABA number against the channel being reauthorized instead of
  # arbitrarily taking the first number, which would misidentify a WABA with multiple numbers.
  def reauthorizing_channel
    return nil if @inbox_id.blank?

    @reauthorizing_channel ||= @account.inboxes.find(@inbox_id).channel
  rescue ActiveRecord::RecordNotFound
    nil
  end

  def create_or_reauthorize_channel(access_token, phone_info)
    if @inbox_id.present?
      Whatsapp::ReauthorizationService.new(
        account: @account,
        inbox_id: @inbox_id,
        phone_number_id: @phone_number_id,
        waba_id: @waba_id
      ).perform(access_token, phone_info)
    else
      waba_info = { waba_id: @waba_id, business_name: phone_info[:business_name] }
      Whatsapp::ChannelCreationService.new(@account, waba_info, phone_info, access_token).perform
    end
  end

  def check_channel_health_and_prompt_reauth(channel)
    health_data = Whatsapp::HealthService.new(channel).fetch_health_status
    return unless health_data

    if channel_in_pending_state?(health_data)
      channel.prompt_reauthorization!
    else
      Rails.logger.info "[WHATSAPP] Channel #{channel.phone_number} health check passed"
    end
  rescue StandardError => e
    Rails.logger.error "[WHATSAPP] Health check failed for channel #{channel.phone_number}: #{e.message}"
  end

  def channel_in_pending_state?(health_data)
    health_data[:platform_type] == 'NOT_APPLICABLE' ||
      health_data.dig(:throughput, 'level') == 'NOT_APPLICABLE'
  end

  def validate_parameters!
    missing_params = []
    missing_params << 'code' if @code.blank?
    missing_params << 'waba_id' if @waba_id.blank?

    return if missing_params.empty?

    raise ArgumentError, "Required parameters are missing: #{missing_params.join(', ')}"
  end
end
