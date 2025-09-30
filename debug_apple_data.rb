#!/usr/bin/env ruby
require_relative 'config/environment'

puts "=== Apple Messages Data Debug ==="

# Find Apple channel
channel = Channel::AppleMessagesForBusiness.first
puts "Channel business_id: #{channel&.business_id}"

# Find conversation
conversation = channel&.inbox&.conversations&.first
puts "Conversation ID: #{conversation&.id}"

if conversation
  puts "\n=== Contact Data ==="
  contact = conversation.contact
  puts "Contact ID: #{contact&.id}"
  puts "Contact additional_attributes: #{contact&.additional_attributes}"

  puts "\n=== Contact Inbox Data ==="
  contact_inbox = conversation.contact_inbox
  puts "ContactInbox ID: #{contact_inbox&.id}"
  puts "ContactInbox source_id: #{contact_inbox&.source_id}"

  puts "\n=== Account Users ==="
  users = conversation.account.users.limit(3)
  users.each do |user|
    puts "User: #{user.email} (ID: #{user.id}, Type: #{user.type})"
  end

  puts "\n=== Account Members (agents) ==="
  members = conversation.account.account_users.limit(3)
  members.each do |member|
    puts "Member: #{member.user&.email} (Role: #{member.role})"
  end
end

puts "\n=== Test Payload Debug ==="
if conversation && channel
  apple_source_id = conversation.contact&.additional_attributes&.dig('apple_messages_source_id')
  puts "Apple source_id from contact: #{apple_source_id}"
  puts "Channel business_id: #{channel.business_id}"

  if apple_source_id
    puts "\nWould send payload:"
    puts "  sourceId: #{channel.business_id}"
    puts "  destinationId: #{apple_source_id}"
    puts "  type: typing_start"
  end
end