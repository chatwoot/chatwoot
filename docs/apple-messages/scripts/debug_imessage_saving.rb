#!/usr/bin/env ruby
require_relative 'config/environment'

puts '=== iMessage Apps Saving Debug ==='

# Find Apple channel
channel = Channel::AppleMessagesForBusiness.first
if channel.nil?
  puts '❌ No Apple Messages for Business channel found'
  exit 1
end

puts "✅ Found channel: #{channel.id}"
puts "📊 Current imessage_apps: #{channel.imessage_apps.inspect}"
puts "📊 Current imessage_apps class: #{channel.imessage_apps.class}"
puts "📊 Current imessage_apps empty?: #{channel.imessage_apps.empty?}"

# Test updating imessage_apps
test_apps = [
  {
    id: 'app_test',
    name: 'Test App',
    app_id: 'com.test.app',
    bid: 'com.apple.messages.MSMessageExtensionBalloonPlugin:com.test.app:extension',
    version: '1.0',
    url: '',
    description: 'Test app for debugging',
    enabled: true,
    use_live_layout: true,
    app_data: {},
    images: []
  }
]

puts "\n=== Testing Save ==="
puts "🧪 Attempting to save: #{test_apps.inspect}"

begin
  channel.update!(imessage_apps: test_apps)
  puts '✅ Save successful!'

  # Reload and verify
  channel.reload
  puts "✅ After reload: #{channel.imessage_apps.inspect}"
  puts "✅ Test app enabled: #{channel.imessage_apps.first&.dig('enabled')}"

rescue StandardError => e
  puts "❌ Save failed: #{e.message}"
  puts "❌ Backtrace: #{e.backtrace.join('\n')}"
end

puts "\n=== Testing EDITABLE_ATTRS ==="
puts "📋 EDITABLE_ATTRS includes imessage_apps: #{Channel::AppleMessagesForBusiness::EDITABLE_ATTRS.include?({ imessage_apps: [] })}"
puts "📋 Full EDITABLE_ATTRS: #{Channel::AppleMessagesForBusiness::EDITABLE_ATTRS.inspect}"
