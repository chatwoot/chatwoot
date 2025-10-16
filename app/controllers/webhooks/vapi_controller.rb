class Webhooks::VapiController < ActionController::API
  def process_payload
    Rails.logger.info "Received Vapi webhook: #{params[:type]}"

    # Validate webhook signature if configured
    if ENV['VAPI_WEBHOOK_SECRET'].present? && !valid_signature?
      Rails.logger.warn 'Invalid Vapi webhook signature'
      render json: { error: 'Invalid signature' }, status: :unauthorized
      return
    end

    # Enqueue job for async processing
    Vapi::CallEventsJob.perform_later(params.to_unsafe_hash)

    render json: { status: 'received' }, status: :ok
  rescue StandardError => e
    Rails.logger.error "Vapi webhook processing error: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    render json: { error: 'Internal server error' }, status: :internal_server_error
  end

  private

  def valid_signature?
    signature = request.headers['X-Vapi-Signature']
    return false if signature.blank?

    expected_signature = OpenSSL::HMAC.hexdigest(
      'SHA256',
      ENV.fetch('VAPI_WEBHOOK_SECRET', nil),
      request.raw_post
    )

    secure_compare(signature, expected_signature)
  end

  def secure_compare(a, b)
    return false if a.blank? || b.blank? || a.length != b.length

    result = 0
    a.bytes.zip(b.bytes) { |x, y| result |= x ^ y }
    result.zero?
  end
end

