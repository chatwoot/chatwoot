# https://api.slack.com/authentication/verifying-requests-from-slack
class Integrations::Slack::SignatureVerifier
  TOLERANCE = 5.minutes.to_i

  # Config reconciliation creates a blank row for this key on upgrade, and that blank row
  # makes GlobalConfigService skip its ENV fallback, so read ENV directly as a last resort.
  def self.signing_secret
    GlobalConfigService.load('SLACK_SIGNING_SECRET', nil).presence || ENV.fetch('SLACK_SIGNING_SECRET', nil)
  end

  def self.valid?(request)
    secret = signing_secret
    timestamp = request.headers['X-Slack-Request-Timestamp']
    signature = request.headers['X-Slack-Signature']
    return false if secret.blank? || timestamp.blank? || signature.blank?
    return false if (Time.current.to_i - timestamp.to_i).abs > TOLERANCE

    # Build over raw bytes so a payload with invalid UTF-8 can't raise on interpolation.
    basestring = "v0:#{timestamp}:".b << request.raw_post
    expected = "v0=#{OpenSSL::HMAC.hexdigest('SHA256', secret, basestring)}"
    ActiveSupport::SecurityUtils.secure_compare(expected, signature)
  end
end
