# frozen_string_literal: true

class Whatsapp::FacebookApiClient
  BASE_URI = 'https://graph.facebook.com'

  def initialize(access_token = nil)
    @access_token = access_token
    @api_version = GlobalConfigService.load('WHATSAPP_API_VERSION', 'v22.0')
  end

  def exchange_code_for_token(code)
    response = HTTParty.get(
      "#{BASE_URI}/#{@api_version}/oauth/access_token",
      query: {
        client_id: GlobalConfigService.load('WHATSAPP_APP_ID', ''),
        client_secret: GlobalConfigService.load('WHATSAPP_APP_SECRET', ''),
        code: code
      }
    )

    handle_response(response, 'Token exchange failed')
  end

  def fetch_phone_numbers(waba_id)
    response = HTTParty.get(
      "#{BASE_URI}/#{@api_version}/#{waba_id}/phone_numbers",
      query: { access_token: @access_token }
    )

    handle_response(response, 'WABA phone numbers fetch failed')
  end

  def debug_token(input_token)
    response = HTTParty.get(
      "#{BASE_URI}/#{@api_version}/debug_token",
      query: {
        input_token: input_token,
        access_token: build_app_access_token
      }
    )

    handle_response(response, 'Token validation failed')
  end

  def register_phone_number(phone_number_id, pin)
    response = HTTParty.post(
      "#{BASE_URI}/#{@api_version}/#{phone_number_id}/register",
      headers: request_headers,
      body: { messaging_product: 'whatsapp', pin: pin.to_s }.to_json
    )

    handle_response(response, 'Phone registration failed')
  end

  def phone_number_verified?(phone_number_id)
    response = HTTParty.get(
      "#{BASE_URI}/#{@api_version}/#{phone_number_id}",
      headers: request_headers
    )

    data = handle_response(response, 'Phone status check failed')
    data['code_verification_status'] == 'VERIFIED'
  end

  def subscribe_waba_webhook(waba_id, callback_url, verify_token)
    response = HTTParty.post(
      "#{BASE_URI}/#{@api_version}/#{waba_id}/subscribed_apps",
      headers: request_headers,
      body: {
        override_callback_uri: callback_url,
        verify_token: verify_token
      }.to_json
    )

    handle_response(response, 'Webhook subscription failed')
  end

  def unsubscribe_waba_webhook(waba_id)
    response = HTTParty.delete(
      "#{BASE_URI}/#{@api_version}/#{waba_id}/subscribed_apps",
      headers: request_headers
    )

    handle_response(response, 'Webhook unsubscription failed')
  end

  def list_message_templates(business_account_id)
    templates = []
    url = "#{BASE_URI}/#{@api_version}/#{business_account_id}/message_templates"

    loop do
      response = HTTParty.get(url, headers: request_headers)
      data = handle_response(response, 'Failed to list message templates')

      templates.concat(data['data'] || [])
      break unless data.dig('paging', 'next')

      url = data['paging']['next']
    end

    templates
  end

  def create_message_template(business_account_id, template_data)
    response = HTTParty.post(
      "#{BASE_URI}/#{@api_version}/#{business_account_id}/message_templates",
      headers: request_headers,
      body: template_data.to_json
    )

    handle_response(response, 'Failed to create message template')
  end

  def delete_message_template(business_account_id, template_name)
    response = HTTParty.delete(
      "#{BASE_URI}/#{@api_version}/#{business_account_id}/message_templates?name=#{template_name}",
      headers: request_headers
    )

    handle_response(response, 'Failed to delete message template')
  end

  # Upload media to Meta and return a handle usable in template creation payloads
  # (example.header_handle for IMAGE/VIDEO/DOCUMENT headers).
  #
  # This follows Meta's upload flow:
  # - POST /{app_id}/uploads -> returns upload session id (id)
  # - POST /{id} with raw bytes -> returns handle (h)
  def upload_template_media(file_bytes:, file_type:)
    app_id = fetch_app_id_from_token
    upload_api_version = GlobalConfigService.load('WHATSAPP_UPLOADS_API_VERSION', 'v24.0')

    session_response = HTTParty.post(
      "#{BASE_URI}/#{upload_api_version}/#{app_id}/uploads",
      headers: request_headers,
      body: {
        file_length: file_bytes.bytesize,
        file_type: file_type
      }.to_json
    )

    session = handle_response(session_response, 'Failed to create upload session')
    upload_id = session['id']
    raise 'Upload session id missing' if upload_id.blank?

    upload_response = HTTParty.post(
      "#{BASE_URI}/#{upload_api_version}/#{upload_id}",
      headers: {
        'Authorization' => "Bearer #{@access_token}",
        'Content-Type' => 'application/octet-stream'
      },
      body: file_bytes
    )

    uploaded = handle_response(upload_response, 'Failed to upload media')
    handle = uploaded['h']
    raise 'Upload handle missing' if handle.blank?

    handle
  end

  private

  def fetch_app_id_from_token
    return @app_id if @app_id.present?

    response = HTTParty.get(
      "#{BASE_URI}/#{@api_version}/debug_token",
      query: {
        input_token: @access_token,
        access_token: @access_token
      }
    )

    data = handle_response(response, 'Token validation failed')
    @app_id = data.dig('data', 'app_id')
    raise 'Failed to determine app_id from token' if @app_id.blank?

    @app_id
  end

  def request_headers
    {
      'Authorization' => "Bearer #{@access_token}",
      'Content-Type' => 'application/json'
    }
  end

  def build_app_access_token
    app_id = GlobalConfigService.load('WHATSAPP_APP_ID', '')
    app_secret = GlobalConfigService.load('WHATSAPP_APP_SECRET', '')
    "#{app_id}|#{app_secret}"
  end

  def handle_response(response, error_message)
    raise "#{error_message}: #{response.body}" unless response.success?

    response.parsed_response
  end
end
