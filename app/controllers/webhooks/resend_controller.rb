# https://resend.com/docs/dashboard/receiving/introduction
class Webhooks::ResendController < ActionController::API
  SIGNATURE_TOLERANCE = 5.minutes

  before_action :verify_signature!

  def inbound
    event = JSON.parse(request_payload)
    ::Webhooks::ResendInboundEmailJob.perform_later(event.dig('data', 'email_id')) if event['type'] == 'email.received'

    head :ok
  end

  private

  def request_payload
    @request_payload ||= request.body.read
  end

  # Svix scheme: base64(HMAC-SHA256(key, "<id>.<timestamp>.<body>")), the secret is "whsec_" + base64 key, the header lists "v1,<sig>".
  def verify_signature!
    id = request.headers['svix-id']
    timestamp = request.headers['svix-timestamp']
    signatures = request.headers['svix-signature']
    return head :unauthorized if [id, timestamp, signatures, signing_key].any?(&:blank?)
    return head :unauthorized if (Time.current.to_i - timestamp.to_i).abs > SIGNATURE_TOLERANCE

    expected = expected_signature(id, timestamp)
    return if signatures.split.any? { |entry| ActiveSupport::SecurityUtils.secure_compare(entry.delete_prefix('v1,'), expected) }

    head :unauthorized
  end

  # An installation that never set the secret must not accept a signature made with an empty key.
  def signing_key
    @signing_key ||= Base64.strict_decode64(ENV.fetch('RESEND_INBOUND_WEBHOOK_SECRET', '').delete_prefix('whsec_'))
  end

  def expected_signature(id, timestamp)
    Base64.strict_encode64(OpenSSL::HMAC.digest('SHA256', signing_key, "#{id}.#{timestamp}.#{request_payload}"))
  end
end
