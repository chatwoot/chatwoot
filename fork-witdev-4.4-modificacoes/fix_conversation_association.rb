#!/usr/bin/env ruby
# Fix conversation association issue

puts "🔧 Fixing Conversation Association Issue"
puts "=" * 50

begin
  # Find conversation 1987 (the one in the URL)
  conv_1987 = Conversation.find(1987)
  puts "📋 CONVERSATION 1987:"
  puts "  - Contact: #{conv_1987.contact.name}"
  puts "  - Phone: #{conv_1987.contact.phone_number}"
  puts "  - Source ID: #{conv_1987.contact_inbox.source_id}"
  puts "  - ContactInbox ID: #{conv_1987.contact_inbox.id}"
  puts

  # Find conversation 2197 (the one used by SendReplyJob)
  conv_2197 = Conversation.find(2197)
  puts "📋 CONVERSATION 2197:"
  puts "  - Contact: #{conv_2197.contact.name}"
  puts "  - Phone: #{conv_2197.contact.phone_number}"
  puts "  - Source ID: #{conv_2197.contact_inbox.source_id}"
  puts "  - ContactInbox ID: #{conv_2197.contact_inbox.id}"
  puts

  # Check if they're for the same contact
  same_contact = conv_1987.contact_id == conv_2197.contact_id
  puts "🔍 ANALYSIS:"
  puts "  - Same contact: #{same_contact}"
  puts "  - Conv 1987 contact_id: #{conv_1987.contact_id}"
  puts "  - Conv 2197 contact_id: #{conv_2197.contact_id}"
  puts

  if same_contact
    puts "✅ Both conversations belong to the same contact (Witalo)"
    puts "💡 The issue is that the system is using different conversations"
    puts "   for the same contact in different contexts."
    puts
    
    # Check which conversation is more recent/active
    puts "📅 CONVERSATION ACTIVITY:"
    puts "  - Conv 1987 last activity: #{conv_1987.last_activity_at}"
    puts "  - Conv 2197 last activity: #{conv_2197.last_activity_at}"
    puts
    
    more_recent = conv_1987.last_activity_at > conv_2197.last_activity_at ? 1987 : 2197
    puts "🎯 More recent conversation: #{more_recent}"
    
    if more_recent == 1987
      puts "✅ Conversation 1987 is more recent - this should be the primary one"
    else
      puts "⚠️  Conversation 2197 is more recent - there might be a routing issue"
    end
  else
    puts "❌ Different contacts - this shouldn't happen!"
  end

rescue => e
  puts "❌ Error: #{e.message}"
  puts e.backtrace.first(5).join("\n")
end

puts
puts "🏁 Analysis completed"