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
    return execute_reauthorization_workflow if embedded_signup_channel?

    error_response('Reauthorization is not supported for this channel type.')
  rescue StandardError => e
    Rails.logger.error "[WHATSAPP_REAUTH] Unexpected error: #{e.message}"
    error_response('An unexpected error occurred. Please try again.')
  end

  private

  def whatsapp_cloud_channel?
    channel.provider == 'whatsapp_cloud'
  end

  def embedded_signup_channel?
    channel.provider == 'whatsapp_cloud' && channel.provider_config['source'] == 'embedded_signup'
  end

  def exchange_code_for_token
    service = Whatsapp::TokenExchangeService.new(code)
    response = service.perform

    # Handle both direct string response and hash response from mocks
    access_token = response.is_a?(Hash) ? response[:access_token] : response

    if access_token.present?
      success_response(nil, { access_token: access_token })
    else
      error_response('Failed to exchange code for access token. Please try again.')
    end
  rescue StandardError => e
    Rails.logger.error "[WHATSAPP_REAUTH] Token exchange error: #{e.message}"
    error_response('Failed to exchange code for access token. Please try again.')
  end

  def validate_token_access(access_token)
    service = Whatsapp::TokenValidationService.new(access_token, waba_id)
    result = service.perform

    # Handle both hash responses (from tests) and successful execution (real service raises on failure)
    if result.is_a?(Hash) && result[:valid] == false
      error_response('The access token does not have the required permissions for WhatsApp.')
    else
      success_response(nil, { valid: true })
    end
  rescue StandardError => e
    Rails.logger.error "[WHATSAPP_REAUTH] Token validation error: #{e.message}"
    error_response('The access token does not have the required permissions for WhatsApp.')
  end

  def fetch_phone_info(access_token)
    service = Whatsapp::PhoneInfoService.new(waba_id, phone_number_id, access_token)
    phone_info = service.perform

    if phone_info && phone_info[:phone_number]
      success_response(nil, { phone_info: phone_info })
    else
      error_response('Failed to fetch phone number information. Please try again.')
    end
  rescue StandardError => e
    Rails.logger.error "[WHATSAPP_REAUTH] Phone info fetch error: #{e.message}"
    error_response('Failed to fetch phone number information. Please try again.')
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

  def execute_reauthorization_workflow
    # Step 1: Exchange code for access token
    token_result = exchange_code_for_token
    return token_result unless token_result[:success]

    access_token = token_result[:data][:access_token]

    # Step 2: Validate token access
    validation_result = validate_token_access(access_token)
    return validation_result unless validation_result[:success]

    # Step 3: Fetch phone info
    phone_result = fetch_phone_info(access_token)
    return phone_result unless phone_result[:success]

    phone_info = phone_result[:data][:phone_info]

    # Step 4: Update channel configuration
    update_channel_config(access_token, phone_info)

    # Step 5: Setup webhooks (optional - don't fail if this fails)
    setup_webhooks(access_token)

    # Step 6: Mark channel as reauthorized
    mark_channel_reauthorized

    success_response('WhatsApp channel reauthorized successfully.')
  end

  def update_channel_config(access_token, phone_info)
    update_channel_provider_config(access_token)
    update_channel_phone_number(phone_info[:phone_number])
    channel.save!
    update_inbox_name(phone_info)
  end

  def update_channel_provider_config(access_token)
    current_config = channel.provider_config || {}
    channel.provider_config = current_config.merge(
      'api_key' => access_token,
      'phone_number_id' => phone_number_id,
      'business_account_id' => business_id
    )
  end

  def update_channel_phone_number(new_phone_number)
    return if new_phone_number.blank? || channel.phone_number == new_phone_number

    existing_channel = Channel::Whatsapp.where(phone_number: new_phone_number).where.not(id: channel.id).first
    if existing_channel.nil?
      channel.phone_number = new_phone_number
    else
      Rails.logger.warn "[WHATSAPP_REAUTH] Skipping phone number update - #{new_phone_number} already exists on " \
                        "channel #{existing_channel.id}"
    end
  end

  def update_inbox_name(phone_info)
    business_name = phone_info[:business_name] || phone_info[:verified_name]
    return if business_name.blank?

    inbox.update!(name: business_name)
  end

  def mark_channel_reauthorized
    channel.reauthorized!
  end

  def success_response(message = nil, data = {})
    {
      success: true,
      message: message,
      data: data
    }
  end

  def error_response(message)
    {
      success: false,
      message: message
    }
  end
end
