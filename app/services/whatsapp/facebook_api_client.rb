class Whatsapp::FacebookApiClient
  BASE_URI = 'https://graph.facebook.com'.freeze
  # Facebook Graph API rate limit error codes
  # 80008: WhatsApp Business Account rate limit
  # 80004: Application rate limit
  # 4: Too many calls
  RATE_LIMIT_ERROR_CODES = [80_008, 80_004, 4].freeze

  def initialize(access_token = nil, account: nil)
    @access_token = access_token
    @account = account
    @api_version = get_api_version
  end

  def exchange_code_for_token(code)
    response = HTTParty.get(
      "#{BASE_URI}/#{@api_version}/oauth/access_token",
      query: {
        client_id: get_app_id,
        client_secret: get_app_secret,
        code: code
        # redirect_uri: 'https://www.facebook.com/'
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

  private

  def request_headers
    {
      'Authorization' => "Bearer #{@access_token}",
      'Content-Type' => 'application/json'
    }
  end

  def build_app_access_token
    "#{get_app_id}|#{get_app_secret}"
  end

  def get_app_id
    @account&.whatsapp_settings&.app_id.presence || GlobalConfigService.load('WHATSAPP_APP_ID', '')
  end

  def get_app_secret
    @account&.whatsapp_settings&.app_secret.presence || GlobalConfigService.load('WHATSAPP_APP_SECRET', '')
  end

  def get_api_version
    @account&.whatsapp_settings&.api_version.presence || GlobalConfigService.load('WHATSAPP_API_VERSION', 'v22.0')
  end

  def handle_response(response, error_message)
    unless response.success?
      # Check if this is a rate limit error
      if rate_limit_error?(response)
        retry_after = extract_retry_after(response)
        error_code = extract_error_code(response)
        raise ::WhatsappRateLimitError.new(
          "#{error_message}: Rate limit exceeded",
          retry_after: retry_after,
          error_code: error_code
        )
      end

      raise "#{error_message}: #{response.body}"
    end

    response.parsed_response
  end

  def rate_limit_error?(response)
    error_code = extract_error_code(response)
    RATE_LIMIT_ERROR_CODES.include?(error_code)
  end

  def extract_retry_after(response)
    # Try to get from header first, then default to 5 minutes
    response.headers['Retry-After']&.to_i || 300
  end

  def extract_error_code(response)
    body = response.body.is_a?(Hash) ? response.body : JSON.parse(response.body)
    body.dig('error', 'code')
  rescue JSON::ParserError, TypeError
    nil
  end
end
