#!/usr/bin/env ruby

# Script để test API toggle_typing_status
# Chạy: rails runner test_typing_api.rb

puts "=== Testing toggle_typing_status API ==="

# Tìm conversation để test
conversation = Conversation.joins(:inbox)
                          .where(inboxes: { channel_type: ['Channel::FacebookPage', 'Channel::Instagram'] })
                          .where(status: 'open')
                          .first

if conversation.nil?
  puts "❌ Không tìm thấy conversation Facebook/Instagram nào để test"
  exit 1
end

puts "✅ Tìm thấy conversation #{conversation.id} (#{conversation.inbox.channel_type})"

# Tìm user agent để test
user = conversation.account.users.where(role: 'agent').first

if user.nil?
  puts "❌ Không tìm thấy agent nào để test"
  exit 1
end

puts "✅ Tìm thấy agent #{user.name} (#{user.id})"

# Test typing ON
puts "\n--- Testing typing ON ---"
begin
  typing_manager = Conversations::TypingStatusManager.new(
    conversation, 
    user, 
    { typing_status: 'on', is_private: false }
  )
  
  typing_manager.toggle_typing_status
  puts "✅ Typing ON - Success"
rescue => e
  puts "❌ Typing ON - Error: #{e.message}"
  puts e.backtrace.first(3).join("\n")
end

# Chờ 2 giây
sleep(2)

# Test typing OFF
puts "\n--- Testing typing OFF ---"
begin
  typing_manager = Conversations::TypingStatusManager.new(
    conversation, 
    user, 
    { typing_status: 'off', is_private: false }
  )
  
  typing_manager.toggle_typing_status
  puts "✅ Typing OFF - Success"
rescue => e
  puts "❌ Typing OFF - Error: #{e.message}"
  puts e.backtrace.first(3).join("\n")
end

puts "\n=== Test completed ==="
puts "Kiểm tra logs để xem chi tiết:"
puts "tail -f log/development.log | grep -i typing"
