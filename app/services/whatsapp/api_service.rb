# Handles WhatsApp API communication
module Whatsapp::ApiService
  extend ActiveSupport::Concern

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

  def register_phone_number(phone_number_id, access_token)
    HTTParty.post(
      "https://graph.facebook.com/#{whatsapp_api_version}/#{phone_number_id}/register",
      {
        headers: { 'Authorization' => "Bearer #{access_token}", 'Content-Type' => 'application/json' },
        body: { messaging_product: 'whatsapp', pin: '212834' }.to_json
      }
    )
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

  private

  def sanitize_phone_number(phone_number)
    return phone_number if phone_number.blank?

    phone_number.gsub(/[\s\-\(\)\.\+]/, '').strip
  end

  def build_app_access_token
    app_id = GlobalConfigService.load('WHATSAPP_APP_ID', '')
    app_secret = GlobalConfigService.load('WHATSAPP_APP_SECRET', '')
    "#{app_id}|#{app_secret}"
  end
end