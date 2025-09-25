#!/usr/bin/env ruby
require_relative 'config/environment'

puts "=== Apple Messages for Business Channels ==="
channels = Channel::AppleMessagesForBusiness.all
if channels.empty?
  puts "No Apple Messages for Business channels found."
else
  channels.each do |channel|
    puts "Channel ID: #{channel.id}"
    puts "MSP ID: #{channel.msp_id}"
    puts "Business ID: #{channel.business_id}"
    puts "Webhook URL: #{channel.webhook_url}"
    puts "Secret: #{channel.secret ? '[PRESENT]' : '[NOT SET]'}"
    puts "---"
  end
end
puts "=== End ==="