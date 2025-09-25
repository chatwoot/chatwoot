#!/usr/bin/env ruby
# Script to update Apple Messages for Business channel webhook URL

require_relative 'config/environment'

puts "=== Updating Apple Messages for Business Webhook URL ==="
puts "Timestamp: #{Time.current}"
puts

# Find the channel
channel = Channel::AppleMessagesForBusiness.first
if channel.nil?
  puts "❌ No Apple Messages for Business channel found."
  exit 1
end

puts "📱 Current Channel Configuration:"
puts "   ID: #{channel.id}"
puts "   MSP ID: #{channel.msp_id}"
puts "   Current Webhook URL: #{channel.webhook_url}"
puts

# Generate the new webhook URL using the Tailscale domain
new_base_url = "https://liquid-m3-pro.tail367da4.ts.net"
new_webhook_url = "#{new_base_url}/webhooks/apple_messages_for_business/#{channel.msp_id}"

puts "🔄 Updating to new webhook URL:"
puts "   New Webhook URL: #{new_webhook_url}"
puts

# Update the channel
begin
  channel.update!(webhook_url: new_webhook_url)
  puts "✅ Successfully updated webhook URL!"
  puts

  # Verify the update
  channel.reload
  puts "📋 Updated Channel Configuration:"
  puts "   ID: #{channel.id}"
  puts "   MSP ID: #{channel.msp_id}"
  puts "   Updated Webhook URL: #{channel.webhook_url}"
  puts

  puts "=== Next Steps ==="
  puts "1. Update the webhook URL in Apple Business Register to:"
  puts "   #{new_webhook_url}"
  puts "2. Test by sending a message from your device"
  puts "3. Monitor logs with: tail -f log/development.log | grep 'AMB Webhook'"

rescue => e
  puts "❌ Failed to update webhook URL: #{e.message}"
  exit 1
end

puts "=== End ==="