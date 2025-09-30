#!/usr/bin/env ruby
# frozen_string_literal: true

# Test script for Apple Messages for Business typing indicator functionality
puts "Testing Apple Messages for Business Typing Indicator Integration"
puts "=" * 60

# Load Rails environment
require_relative 'config/environment'

# Find an Apple Messages for Business channel
apple_channel = Channel::AppleMessagesForBusiness.first

unless apple_channel
  puts "❌ No Apple Messages for Business channels found"
  puts "Please create an Apple Messages channel first"
  exit 1
end

puts "✅ Found Apple Messages channel: #{apple_channel.business_id}"

# Find a conversation on this channel
conversation = apple_channel.inbox.conversations.first

unless conversation
  puts "❌ No conversations found for this Apple Messages channel"
  puts "Please create a conversation first"
  exit 1
end

puts "✅ Found conversation: #{conversation.id}"

# Check if contact has Apple Messages source_id (destination_id)
apple_source_urn = conversation.contact&.additional_attributes&.dig('apple_messages_source_id')
unless apple_source_urn
  puts "❌ Contact doesn't have apple_messages_source_id (destination_id)"
  puts "Contact: #{conversation.contact&.id}"
  puts "Additional attributes: #{conversation.contact&.additional_attributes}"
  exit 1
end

# Extract UUID from URN format
apple_source_id = apple_source_urn.sub(/^urn:biz:/, '')
puts "✅ Contact has Apple Messages destination_id: #{apple_source_id} (from URN: #{apple_source_urn})"

# Test the typing indicator service directly
puts "\n🧪 Testing typing indicator service..."

# Test typing start
puts "  → Testing typing_start..."
start_service = AppleMessagesForBusiness::OutgoingTypingIndicatorService.new(
  channel: apple_channel,
  destination_id: apple_source_id,
  action: :start
)

start_result = start_service.perform
if start_result[:success]
  puts "  ✅ typing_start sent successfully"
  puts "     Message ID: #{start_result[:message_id]}"
else
  puts "  ❌ typing_start failed: #{start_result[:error]}"
end

# Wait a moment
sleep 2

# Test typing end
puts "  → Testing typing_end..."
end_service = AppleMessagesForBusiness::OutgoingTypingIndicatorService.new(
  channel: apple_channel,
  destination_id: apple_source_id,
  action: :end
)

end_result = end_service.perform
if end_result[:success]
  puts "  ✅ typing_end sent successfully"
  puts "     Message ID: #{end_result[:message_id]}"
else
  puts "  ❌ typing_end failed: #{end_result[:error]}"
end

# Test integration with typing status manager
puts "\n🔗 Testing integration with typing status manager..."

# Create a mock user for testing
account_user = conversation.account.account_users.first
unless account_user
  puts "❌ No account users found"
  exit 1
end

user = account_user.user
puts "✅ Using test user: #{user.email} (Role: #{account_user.role})"

# Test typing on
puts "  → Testing typing 'on' integration..."
typing_manager = Conversations::TypingStatusManager.new(
  conversation,
  user,
  { typing_status: 'on', is_private: false }
)

begin
  typing_manager.toggle_typing_status
  puts "  ✅ Typing 'on' integration successful"
rescue => e
  puts "  ❌ Typing 'on' integration failed: #{e.message}"
end

# Wait a moment
sleep 2

# Test typing off
puts "  → Testing typing 'off' integration..."
typing_manager = Conversations::TypingStatusManager.new(
  conversation,
  user,
  { typing_status: 'off', is_private: false }
)

begin
  typing_manager.toggle_typing_status
  puts "  ✅ Typing 'off' integration successful"
rescue => e
  puts "  ❌ Typing 'off' integration failed: #{e.message}"
end

puts "\n" + "=" * 60
puts "✅ Apple Messages for Business typing indicator test completed!"
puts "Check your Apple Messages app to see the typing indicators"