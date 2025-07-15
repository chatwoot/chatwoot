class Whatsapp::ReauthorizationService
  attr_reader :inbox, :code, :business_id, :waba_id, :phone_number_id

  def initialize(inbox:, code:, business_id:, waba_id:, phone_number_id:)
    @inbox = inbox
    @code = code
    @business_id = business_id
    @waba_id = waba_id
    @phone_number_id = phone_number_id
  end

  def perform
    return embedded_signup_reauth if embedded_signup_channel?

    { success: false, message: I18n.t('errors.whatsapp.reauthorization.not_supported') }
  end

  private

  def embedded_signup_channel?
    channel.provider == 'whatsapp_cloud' && channel.provider_config['source'] == 'embedded_signup'
  end

  def embedded_signup_reauth
    # Exchange code for access token
    token_response = exchange_code_for_token
    return token_response unless token_response[:success]

    # Validate token has WABA access
    validation_response = validate_token_access(token_response[:access_token])
    return validation_response unless validation_response[:success]

    # Fetch phone info
    phone_info_response = fetch_phone_info(token_response[:access_token])
    return phone_info_response unless phone_info_response[:success]

    ActiveRecord::Base.transaction do
      # Update channel configuration
      update_channel_config(
        access_token: token_response[:access_token],
        phone_info: phone_info_response[:phone_info]
      )

      # Mark as reauthorized
      channel.reauthorized!
    end

    # Setup webhooks again (outside transaction)
    setup_webhooks(token_response[:access_token])

    { success: true }
  rescue StandardError => e
    Rails.logger.error "[WHATSAPP_REAUTH] Error: #{e.message}"
    { success: false, message: I18n.t('errors.whatsapp.reauthorization.generic') }
  end

  def exchange_code_for_token
    service = Whatsapp::TokenExchangeService.new(code: code)
    response = service.perform

    if response[:access_token].present?
      { success: true, access_token: response[:access_token] }
    else
      { success: false, message: I18n.t('errors.whatsapp.token_exchange_failed') }
    end
  end

  def validate_token_access(access_token)
    service = Whatsapp::TokenValidationService.new(
      access_token: access_token,
      waba_id: waba_id
    )
    response = service.perform

    if response[:valid]
      { success: true }
    else
      { success: false, message: I18n.t('errors.whatsapp.invalid_token_permissions') }
    end
  end

  def fetch_phone_info(access_token)
    service = Whatsapp::PhoneInfoService.new(
      access_token: access_token,
      phone_number_id: phone_number_id
    )
    response = service.perform

    if response[:phone_number].present?
      { success: true, phone_info: response }
    else
      { success: false, message: I18n.t('errors.whatsapp.phone_info_fetch_failed') }
    end
  end

  def update_channel_config(access_token:, phone_info:)
    # Preserve existing config and update with new values
    updated_config = channel.provider_config.merge(
      'api_key' => access_token,
      'phone_number_id' => phone_number_id,
      'business_account_id' => business_id
    )

    # Update phone number if changed
    channel.update!(
      phone_number: phone_info[:phone_number],
      provider_config: updated_config
    )
  end

  def setup_webhooks(access_token)
    return unless channel.provider == 'whatsapp_cloud'

    Whatsapp::WebhookSetupService.new(channel, business_id, access_token).perform
  rescue StandardError => e
    Rails.logger.error "[WHATSAPP_REAUTH] Webhook setup failed: #{e.message}"
    # Don't fail the reauthorization if webhook setup fails
  end

  def channel
    @channel ||= inbox.channel
  end
end
