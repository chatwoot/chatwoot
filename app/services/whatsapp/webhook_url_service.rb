class Whatsapp::WebhookUrlService
  def generate_webhook_url(phone_number: nil)
    base_url = determine_base_url
    webhook_path = determine_webhook_path(phone_number: phone_number)

    "#{base_url}#{webhook_path}"
  end

  def should_update_webhook_url?(current_url, phone_number)
    return false if phone_number.blank?

    expected_url = generate_webhook_url(phone_number: phone_number)
    current_url != expected_url
  end

  private

  def determine_base_url
    # For local development, allow tunnel override (ngrok, etc.)
    local_tunnel = ENV.fetch('WEBHOOK_URL_TUNNEL', nil)
    return ensure_protocol(local_tunnel) if local_tunnel.present?

    # Use FRONTEND_URL (same pattern as existing webhook generation)
    frontend_url = ENV.fetch('FRONTEND_URL', nil)
    return frontend_url if frontend_url.present?

    # Should not happen if FRONTEND_URL is properly configured
    raise ArgumentError, 'FRONTEND_URL environment variable must be set'
  end

  def determine_webhook_path(phone_number: nil)
    if phone_number.present?
      # Same pattern as Inbox#callback_webhook_url for 'Channel::Whatsapp'
      "/webhooks/whatsapp/#{phone_number}"
    else
      # For initial setup before phone number is known (WHAPI endpoint)
      '/webhooks/whapi'
    end
  end

  def ensure_protocol(url)
    url.start_with?('http') ? url : "https://#{url}"
  end
end
