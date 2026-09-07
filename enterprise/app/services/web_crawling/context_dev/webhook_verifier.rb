class WebCrawling::ContextDev::WebhookVerifier
  # Context.dev requires stale signatures to be rejected but does not prescribe a tolerance.
  # Source: https://app.stainless.com/api/spec/documented/context.dev/openapi.documented.yml
  TIMESTAMP_TOLERANCE = 5.minutes

  def initialize(payload:, signature:, secret:)
    @payload = payload
    @signature = signature
    @secret = secret
  end

  def valid?
    timestamp, signature = signature_parts
    return false if timestamp.blank? || signature.blank? || @secret.blank?
    return false if (Time.current.to_i - timestamp.to_i).abs > TIMESTAMP_TOLERANCE

    expected = OpenSSL::HMAC.hexdigest('SHA256', @secret, "#{timestamp}.#{@payload}")
    ActiveSupport::SecurityUtils.secure_compare(expected, signature)
  rescue ArgumentError, TypeError
    false
  end

  private

  def signature_parts
    parts = @signature.to_s.split(',').to_h { |part| part.split('=', 2) }
    [Integer(parts['t'], 10), parts['v1']]
  end
end
