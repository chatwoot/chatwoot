class AppleMessagesForBusiness::MerchantSessionService
  def initialize(channel)
    @channel = channel
  end

  def create_session
    validate_merchant_configuration
    return { error: 'Merchant configuration invalid' } unless merchant_configured?

    begin
      session_data = request_merchant_session

      {
        success: true,
        session_data: session_data,
        expires_at: 5.minutes.from_now,
        merchant_identifier: merchant_identifier
      }
    rescue StandardError => e
      {
        error: "Merchant session creation failed: #{e.message}"
      }
    end
  end

  def validate_session(session_id)
    stored_session = get_stored_session(session_id)
    return { valid: false, error: 'Session not found' } unless stored_session

    if Time.current > Time.parse(stored_session['expires_at'])
      { valid: false, error: 'Session expired' }
    else
      { valid: true, session: stored_session }
    end
  end

  def renew_session(session_id)
    # Renew an existing merchant session
    old_session = get_stored_session(session_id)
    return { error: 'Session not found' } unless old_session

    # Create a new session
    new_session = create_session
    return new_session if new_session[:error]

    # Store the renewed session
    store_session(session_id, new_session[:session_data])

    new_session
  end

  private

  def merchant_configured?
    merchant_certificate.present? &&
    merchant_identifier.present? &&
    merchant_domain.present?
  end

  def validate_merchant_configuration
    errors = []

    errors << 'Missing merchant certificate' unless merchant_certificate.present?
    errors << 'Missing merchant identifier' unless merchant_identifier.present?
    errors << 'Missing merchant domain' unless merchant_domain.present?

    if errors.any?
      Rails.logger.error "Apple Pay merchant configuration errors: #{errors.join(', ')}"
      false
    else
      true
    end
  end

  def request_merchant_session
    # Create the merchant session request
    session_request = {
      merchantIdentifier: merchant_identifier,
      displayName: @channel.name,
      initiative: 'messaging',
      initiativeContext: merchant_domain
    }

    # Sign the request with merchant certificate
    signed_request = sign_merchant_session_request(session_request)

    # Make request to Apple Pay
    response = HTTParty.post(
      'https://apple-pay-gateway.apple.com/paymentservices/startSession',
      body: signed_request,
      headers: {
        'Content-Type' => 'application/json'
      },
      timeout: 30
    )

    if response.success?
      session_data = JSON.parse(response.body)
      store_session(SecureRandom.hex(16), session_data)
      session_data
    else
      raise "Apple Pay API error: #{response.code} - #{response.body}"
    end
  end

  def sign_merchant_session_request(session_request)
    # Load merchant certificate and private key
    cert = OpenSSL::X509::Certificate.new(merchant_certificate)
    private_key = OpenSSL::PKey::RSA.new(merchant_private_key)

    # Create PKCS#7 signed data
    data = session_request.to_json
    signed_data = OpenSSL::PKCS7.sign(cert, private_key, data, [], OpenSSL::PKCS7::BINARY)

    # Convert to DER format
    signed_data.to_der
  end

  def store_session(session_id, session_data)
    # Store session in Redis for quick access
    session_key = "apple_pay_session:#{@channel.id}:#{session_id}"

    Redis.current.setex(
      session_key,
      300, # 5 minutes
      {
        session_data: session_data,
        created_at: Time.current.iso8601,
        expires_at: 5.minutes.from_now.iso8601,
        channel_id: @channel.id
      }.to_json
    )

    session_id
  end

  def get_stored_session(session_id)
    session_key = "apple_pay_session:#{@channel.id}:#{session_id}"
    session_json = Redis.current.get(session_key)

    return nil unless session_json

    JSON.parse(session_json)
  rescue JSON::ParserError
    nil
  end

  def merchant_certificate
    @channel.merchant_certificates ||
    ENV['APPLE_PAY_MERCHANT_CERTIFICATE']
  end

  def merchant_private_key
    # Extract private key from certificate or use separate key
    @channel.payment_settings.dig('apple_pay', 'private_key') ||
    ENV['APPLE_PAY_MERCHANT_PRIVATE_KEY']
  end

  def merchant_identifier
    @channel.payment_settings.dig('apple_pay', 'merchant_identifier') ||
    ENV['APPLE_PAY_MERCHANT_IDENTIFIER']
  end

  def merchant_domain
    @channel.payment_settings.dig('apple_pay', 'merchant_domain') ||
    ENV['APPLE_PAY_MERCHANT_DOMAIN'] ||
    ENV['BASE_URL']&.gsub(/^https?:\/\//, '')
  end
end