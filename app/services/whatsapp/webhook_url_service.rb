class Whatsapp::WebhookUrlService
  """
  Service to generate dynamic webhook URLs for WhatsApp channels
  Uses the EXACT SAME pattern as app/models/inbox.rb#callback_webhook_url
  This ensures consistency with the authoritative source of webhook URL generation
  
  Configuration:
  - Uses FRONTEND_URL environment variable (same as Inbox model)
  - Supports WEBHOOK_URL_TUNNEL for local development override
  - Follows existing hardcoded path patterns used throughout the app
  """

  def generate_webhook_url(phone_number: nil)
    """
    Generate webhook URL using dynamic configuration from environment
    
    Args:
      phone_number: Optional phone number to include in webhook path
      
    Returns:
      String: Complete webhook URL for the current environment
    """
    
    base_url = determine_base_url
    webhook_path = determine_webhook_path(phone_number: phone_number)
    
    "#{base_url}#{webhook_path}"
  end

  def should_update_webhook_url?(current_url, phone_number)
    """
    Check if webhook URL needs to be updated with phone number
    
    Args:
      current_url: Current webhook URL
      phone_number: Phone number to check against
      
    Returns:
      Boolean: True if URL should be updated
    """
    return false if phone_number.blank?
    
    expected_url = generate_webhook_url(phone_number: phone_number)
    current_url != expected_url
  end

  private

  def determine_base_url
    """
    Get base URL using existing application configuration
    Priority: WEBHOOK_URL_TUNNEL (local dev override) -> FRONTEND_URL (standard)
    
    Same pattern as used throughout the app (see app/models/inbox.rb)
    """
    
    # For local development, allow tunnel override (ngrok, etc.)
    local_tunnel = ENV['WEBHOOK_URL_TUNNEL']
    if local_tunnel.present?
      return ensure_protocol(local_tunnel)
    end
    
    # Use FRONTEND_URL (same pattern as existing webhook generation)
    frontend_url = ENV.fetch('FRONTEND_URL', nil)
    if frontend_url.present?
      return frontend_url
    end
    
    # Should not happen if FRONTEND_URL is properly configured
    raise ArgumentError, 'FRONTEND_URL environment variable must be set'
  end

  def determine_webhook_path(phone_number: nil)
    """
    Generate webhook path using the EXACT same pattern as app/models/inbox.rb#callback_webhook_url
    This ensures consistency with the authoritative source used throughout the application
    
    Args:
      phone_number: Optional phone number for URL path
      
    Returns:
      String: Webhook path matching existing app patterns
    """
    
    if phone_number.present?
      # Same pattern as Inbox#callback_webhook_url for 'Channel::Whatsapp'
      "/webhooks/whatsapp/#{phone_number}"
    else
      # For initial setup before phone number is known (WHAPI endpoint)
      "/webhooks/whapi"
    end
  end

  def ensure_protocol(url)
    """
    Ensure URL has proper protocol
    
    Args:
      url: URL string to check
      
    Returns:
      String: URL with protocol
    """
    url.start_with?('http') ? url : "https://#{url}"
  end
end
