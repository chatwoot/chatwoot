class Whatsapp::EmbeddedSignupService
  include Rails.application.routes.url_helpers

  def initialize(account:, code:, business_id:, waba_id:, phone_number_id:)
    @account = account
    @code = code
    @business_id = business_id
    @waba_id = waba_id
    @phone_number_id = phone_number_id
  end

  def perform
    # Validate required parameters
    unless @code.present? && @business_id.present? && @waba_id.present? && @phone_number_id.present?
      raise ArgumentError, 'Code, business_id, waba_id, and phone_number_id are all required'
    end

    GlobalConfig.clear_cache
    # Exchange code for user access token
    access_token = exchange_code_for_token

    # Use the provided business info directly (more efficient)
    phone_info = fetch_phone_info_via_waba(@waba_id, @phone_number_id, access_token)

    # Validate that the token has access to the provided WABA (security check)
    validate_token_waba_access(access_token, @waba_id)

    waba_info = { waba_id: @waba_id, business_name: phone_info[:business_name] }

    create_or_update_channel(waba_info, phone_info, access_token)
  rescue StandardError => e
    Rails.logger.error("[WHATSAPP] Signup failed: #{e.message}")
    raise e
  end

  private

  def whatsapp_api_version
    @whatsapp_api_version ||= GlobalConfigService.load('WHATSAPP_API_VERSION', 'v22.0')
  end

  def exchange_code_for_token
    response = Faraday.get(
      "https://graph.facebook.com/#{whatsapp_api_version}/oauth/access_token",
      {
        client_id: GlobalConfigService.load('WHATSAPP_APP_ID', ''),
        client_secret: GlobalConfigService.load('WHATSAPP_APP_SECRET', ''),
        code: @code
      }
    )

    raise "Token exchange failed: #{response.body}" unless response.success?

    data = JSON.parse(response.body)
    raise "No access token in response: #{data}" unless data['access_token']

    data['access_token']
  end

  def fetch_phone_info_via_waba(waba_id, phone_number_id, access_token)
    # Get all phone numbers for the WABA
    response = Faraday.get(
      "https://graph.facebook.com/#{whatsapp_api_version}/#{waba_id}/phone_numbers",
      { access_token: access_token }
    )

    raise "WABA phone numbers fetch failed: #{response.body}" unless response.success?

    data = JSON.parse(response.body)
    phone_numbers = data['data']
    phone_data = phone_numbers.find { |phone| phone['id'] == phone_number_id } || phone_numbers.first

    raise "No phone numbers found for WABA #{waba_id}" if phone_data.nil?

    display_phone_number = sanitize_phone_number(phone_data['display_phone_number'])
    {
      phone_number_id: phone_data['id'],
      phone_number: "+#{display_phone_number}",
      verified: phone_data['code_verification_status'] == 'VERIFIED',
      business_name: phone_data['verified_name'] || phone_data['display_phone_number']
    }
  end

  def create_or_update_channel(waba_info, phone_info, access_token)
    existing_channel = find_existing_channel(phone_info[:phone_number])
    channel_attributes = build_channel_attributes(waba_info, phone_info, access_token)

    if existing_channel
      Rails.logger.error("Channel already exists: #{existing_channel.inspect}")
      raise "Channel already exists: #{existing_channel.phone_number}"
    else
      channel = create_new_channel(channel_attributes, phone_info)
      register_phone_number(phone_info[:phone_number_id], access_token)
      override_waba_webhook(waba_info[:waba_id], channel, access_token)
      channel
    end
  end

  def register_phone_number(phone_number_id, access_token)
    HTTParty.post(
      "https://graph.facebook.com/#{whatsapp_api_version}/#{phone_number_id}/register",
      {
        headers: { 'Authorization' => "Bearer #{access_token}", 'Content-Type' => 'application/json' },
        body: { messaging_product: 'whatsapp', pin: '212834' }.to_json
      }
    )
  end

  def find_existing_channel(phone_number)
    Channel::Whatsapp.find_by(account: @account, phone_number: phone_number)
  end

  def build_channel_attributes(waba_info, phone_info, access_token)
    {
      phone_number: phone_info[:phone_number],
      provider: 'whatsapp_cloud',
      provider_config: {
        api_key: access_token,
        phone_number_id: phone_info[:phone_number_id],
        business_account_id: waba_info[:waba_id],
        source: 'embedded_signup'
      }
    }
  end

  def create_new_channel(attributes, phone_info)
    channel = Channel::Whatsapp.create!(account: @account, **attributes)
    create_inbox_for_channel(channel, phone_info)
    channel.reload
    channel
  end

  def create_inbox_for_channel(channel, phone_info)
    Inbox.create!(
      account: @account,
      name: "#{phone_info[:business_name]} WhatsApp",
      channel: channel
    )
  end

  def sanitize_phone_number(phone_number)
    return phone_number if phone_number.blank?

    phone_number.gsub(/[\s\-\(\)\.\+]/, '').strip
  end

  def validate_token_waba_access(access_token, waba_id)
    token_debug_data = fetch_token_debug_data(access_token)
    waba_scope = extract_waba_scope(token_debug_data)
    verify_waba_authorization(waba_scope, waba_id)
  end

  def fetch_token_debug_data(access_token)
    response = Faraday.get(
      "https://graph.facebook.com/#{whatsapp_api_version}/debug_token",
      {
        input_token: access_token,
        access_token: build_app_access_token
      }
    )

    raise "Token validation failed: #{response.body}" unless response.success?

    JSON.parse(response.body)
  end

  def extract_waba_scope(token_data)
    granular_scopes = token_data.dig('data', 'granular_scopes')
    waba_scope = granular_scopes&.find { |scope| scope['scope'] == 'whatsapp_business_management' }

    raise 'No WABA scope found in token' unless waba_scope

    waba_scope
  end

  def verify_waba_authorization(waba_scope, waba_id)
    authorized_waba_ids = waba_scope['target_ids'] || []

    return if authorized_waba_ids.include?(waba_id)

    raise "Token does not have access to WABA #{waba_id}. Authorized WABAs: #{authorized_waba_ids}"
  end

  def build_app_access_token
    app_id = GlobalConfigService.load('WHATSAPP_APP_ID', '')
    app_secret = GlobalConfigService.load('WHATSAPP_APP_SECRET', '')
    "#{app_id}|#{app_secret}"
  end

  def override_waba_webhook(waba_id, channel, access_token)
    callback_url = "#{ENV.fetch('FRONTEND_URL', nil)}/webhooks/whatsapp/#{channel.phone_number}"
    verify_token = channel.provider_config['webhook_verify_token']

    response = HTTParty.post(
      "https://graph.facebook.com/#{whatsapp_api_version}/#{waba_id}/subscribed_apps",
      {
        headers: {
          'Authorization' => "Bearer #{access_token}",
          'Content-Type' => 'application/json'
        },
        body: {
          override_callback_uri: callback_url,
          verify_token: verify_token
        }.to_json
      }
    )

    return if response.success?

    Rails.logger.error("[WHATSAPP] Webhook override failed: #{response.body}")
    raise "Webhook override failed: #{response.body}"
  end
end
