class Webhooks::CalendlyController < ActionController::API
  def receive
    verify_signature!
    process_event
    head :ok
  rescue StandardError => e
    Rails.logger.error("Calendly webhook error: #{e.message}")
    head :unauthorized
  end

  private

  def process_event
    hook = find_hook_for_event
    return if hook.blank?

    Integrations::Calendly::WebhookJob.perform_later(hook, parsed_body['event'], parsed_body['payload'].to_json)
  end

  def verify_signature!
    signature_header = request.headers['Calendly-Webhook-Signature']
    raise 'Missing webhook signature' if signature_header.blank?

    parsed = parse_signature_header(signature_header)
    validate_signature!(parsed[:timestamp], parsed[:signature])
  end

  def parse_signature_header(header)
    parts = header.split(',').to_h { |part| part.split('=', 2) }
    timestamp = parts['t']
    signature = parts['v1']
    raise 'Invalid signature format' if timestamp.blank? || signature.blank?

    { timestamp: timestamp, signature: signature }
  end

  def validate_signature!(timestamp, received_signature)
    hook = find_hook_for_event
    raise 'No matching Calendly hook found' if hook.blank?

    signing_key = hook.settings['signing_key']
    raise 'No signing key configured' if signing_key.blank?

    expected = OpenSSL::HMAC.hexdigest('SHA256', signing_key, "#{timestamp}.#{raw_body}")
    return if ActiveSupport::SecurityUtils.secure_compare(expected, received_signature)

    raise 'Invalid webhook signature'
  end

  def find_hook_for_event
    @find_hook_for_event ||= find_hook_by_user_uri
  end

  def find_hook_by_user_uri
    created_by = parsed_body['created_by']
    return if created_by.blank?

    Integrations::Hook.where(app_id: 'calendly').find do |hook|
      hook.settings['calendly_user_uri'] == created_by
    end
  end

  def parsed_body
    @parsed_body ||= JSON.parse(raw_body)
  end

  def raw_body
    @raw_body ||= request.body.read
  end
end
