# Apple Messages for Business Configuration
# This initializer handles automatic webhook URL configuration for development environment

Rails.application.configure do
  # Only run in development environment
  if Rails.env.development?
    # Auto-configure webhook URLs for Apple Messages for Business channels
    Rails.application.config.after_initialize do
      # Wait for Rails to fully initialize before updating webhook URLs
      Rails.application.executor.wrap do
        begin
          # Use environment variable, or check for active dev server URL, or fallback to localhost
          base_url = ENV.fetch('FRONTEND_URL', nil) || detect_active_public_url || 'http://localhost:10750'
          base_url = "https://#{base_url}" unless base_url.start_with?('http://', 'https://')
          base_url = base_url.sub(/^https?:\/\/https?:\/\//, 'https://') # Fix double protocol
          Rails.logger.info "[Apple Messages for Business] Using URL: #{base_url}"

          # Update all Apple Messages for Business channels with the detected URL
          Channel::AppleMessagesForBusiness.find_each do |channel|
            old_webhook_url = channel.webhook_url
            new_webhook_url = "#{base_url}/webhooks/apple_messages_for_business/#{channel.msp_id}"

            if old_webhook_url != new_webhook_url
              channel.update!(webhook_url: new_webhook_url)
              Rails.logger.info "[Apple Messages for Business] Updated webhook URL for channel #{channel.id}: #{new_webhook_url}"
            else
              Rails.logger.info "[Apple Messages for Business] Webhook URL already correct for channel #{channel.id}: #{new_webhook_url}"
            end
          end
        rescue => e
          Rails.logger.error "[Apple Messages for Business] Error updating webhook URLs: #{e.message}"
        end
      end
    end
  end
end

private

# Detect the active public URL by checking what the dev server is using
def detect_active_public_url
  begin
    # Check if Tailscale URL is saved (from dev-server.sh)
    tailscale_url_file = Rails.root.join('tmp', 'pids', 'tailscale_url.txt')
    if File.exist?(tailscale_url_file)
      tailscale_url = File.read(tailscale_url_file).strip
      return tailscale_url if tailscale_url.present?
    end

    # Check if ngrok is running by trying to fetch tunnel info
    require 'net/http'
    uri = URI('http://localhost:4040/api/tunnels')
    response = Net::HTTP.get_response(uri)
    if response.is_a?(Net::HTTPSuccess)
      require 'json'
      tunnels = JSON.parse(response.body)
      public_url = tunnels.dig('tunnels', 0, 'public_url')
      return public_url.sub(/^https?:\/\//, '') if public_url&.include?('https')
    end
  rescue => e
    Rails.logger.debug "[Apple Messages for Business] Could not detect active public URL: #{e.message}"
  end

  # Check if custom domain mode is being used (nginx running on port 443)
  begin
    require 'socket'
    TCPSocket.new('localhost', 443).close
    return 'dev.rhaps.net'  # Custom domain is available
  rescue Errno::ECONNREFUSED
    # Custom domain not available
  end

  nil
end