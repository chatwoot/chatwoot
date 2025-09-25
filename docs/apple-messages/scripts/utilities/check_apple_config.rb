#!/usr/bin/env ruby
# Script to check Apple Messages for Business channel configuration

require_relative 'config/environment'

puts "=== Apple Messages for Business Channel Configuration ==="
puts "Timestamp: #{Time.current}"
puts

channels = Channel::AppleMessagesForBusiness.all
if channels.empty?
  puts "❌ No Apple Messages for Business channels found."
  puts "   You need to create an Apple Messages for Business inbox in Chatwoot first."
else
  channels.each_with_index do |channel, index|
    puts "📱 Channel ##{index + 1}:"
    puts "   ID: #{channel.id}"
    puts "   MSP ID: #{channel.msp_id}"
    puts "   Business ID: #{channel.business_id}"
    puts "   Webhook URL: #{channel.webhook_url}"
    puts "   Secret: #{channel.secret ? '[SET]' : '[NOT SET]'}"
    puts "   Account: #{channel.account.name} (ID: #{channel.account_id})"
    puts "   Created: #{channel.created_at}"
    puts

    # Generate the expected webhook URLs based on the MSP ID and current environment
    base_url = detect_active_public_url || 'localhost:10750'
    base_url = "https://#{base_url}" unless base_url.start_with?('http')
    puts "   📡 Expected webhook URLs for Apple Business Register:"
    puts "   ├─ Main: #{base_url}/webhooks/apple_messages_for_business/#{channel.msp_id}"
    puts "   └─ Alt:  #{base_url}/webhooks/apple_messages_for_business/#{channel.msp_id}/message"
    puts

    # Show what Business ID customers should message
    puts "   💬 Customers should message:"
    puts "   └─ https://bcrw.apple.com/urn:biz:#{channel.business_id}"
    puts
    puts "   " + "─" * 70
    puts
  end
end

puts "=== Next Steps ==="
puts "1. Configure webhook URL in Apple Business Register to match the expected URL above"
puts "2. Ensure your Business ID matches what customers are messaging"
puts "3. Test by sending a message from your device"
puts "4. Monitor logs with: tail -f log/development.log | grep 'AMB Webhook'"
puts "=== End ==="

# Helper method to detect the active public URL by checking what the dev server is using
def detect_active_public_url
  begin
    # Check if Tailscale URL is saved (from dev-server.sh)
    tailscale_url_file = File.join(Rails.root, 'tmp', 'pids', 'tailscale_url.txt')
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
    # Silent error handling for debug script
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