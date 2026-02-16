class Webhooks::CalendlyController < ActionController::API
  class SignatureError < StandardError; end

  TIMESTAMP_TOLERANCE = 5.minutes
  TIMESTAMP_FUTURE_TOLERANCE = 1.minute

  def receive
    verify_signature!
    process_event
    head :ok
  rescue SignatureError => e
    Rails.logger.error("Calendly webhook signature error: #{e.message}")
    head :unauthorized
  rescue StandardError => e
    Rails.logger.error("Calendly webhook processing error: #{e.message}")
    head :internal_server_error
  end

  private

  def process_event
    hook = find_hook_for_event
    return if hook.blank?

    Integrations::Calendly::WebhookJob.perform_later(hook, parsed_body['event'], parsed_body['payload'].to_json)
  end

  def verify_signature!
    signature_header = request.headers['Calendly-Webhook-Signature']
    raise SignatureError, 'Missing webhook signature' if signature_header.blank?

    parsed = parse_signature_header(signature_header)
    validate_timestamp!(parsed[:timestamp])
    validate_signature!(parsed[:timestamp], parsed[:signature])
  end

  def parse_signature_header(header)
    parts = header.split(',').to_h { |part| part.split('=', 2) }
    timestamp = parts['t']
    signature = parts['v1']
    raise SignatureError, 'Invalid signature format' if timestamp.blank? || signature.blank?

    { timestamp: timestamp, signature: signature }
  end

  def validate_timestamp!(timestamp)
    webhook_time = Time.zone.at(timestamp.to_i)
    now = Time.current

    raise SignatureError, 'Webhook timestamp too old' if webhook_time < now - TIMESTAMP_TOLERANCE
    raise SignatureError, 'Webhook timestamp too far in the future' if webhook_time > now + TIMESTAMP_FUTURE_TOLERANCE
  end

  def validate_signature!(timestamp, received_signature)
    hook = find_hook_for_event
    raise SignatureError, 'No matching Calendly hook found' if hook.blank?

    signing_key = resolve_signing_key(hook)
    raise SignatureError, 'No signing key configured' if signing_key.blank?

    expected = OpenSSL::HMAC.hexdigest('SHA256', signing_key, "#{timestamp}.#{raw_body}")
    return if ActiveSupport::SecurityUtils.secure_compare(expected, received_signature)

    raise SignatureError, 'Invalid webhook signature'
  end

  def resolve_signing_key(hook)
    hook.settings['signing_key'].presence || GlobalConfigService.load('CALENDLY_WEBHOOK_SIGNING_KEY', nil)
  end

  def find_hook_for_event
    @find_hook_for_event ||= find_hook_by_user_uri
  end

  def find_hook_by_user_uri
    created_by = parsed_body['created_by']
    return if created_by.blank?

    Integrations::Hook.where(app_id: 'calendly')
                      .where("settings->>'calendly_user_uri' = ?", created_by)
                      .first
  end

  def parsed_body
    @parsed_body ||= JSON.parse(raw_body)
  end

  def raw_body
    @raw_body ||= request.body.read
  end
end
