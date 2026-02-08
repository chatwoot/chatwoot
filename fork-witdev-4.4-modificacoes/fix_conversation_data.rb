#!/usr/bin/env ruby
# Script to fix conversation data inconsistency

puts "🔧 Fixing Conversation Data Inconsistency"
puts "=" * 50

begin
  # Clear Rails cache
  puts "🧹 Clearing Rails cache..."
  Rails.cache.clear
  puts "✅ Cache cleared"
  
  # Reload conversation 1987
  puts "🔄 Reloading conversation 1987..."
  conversation = Conversation.find(1987)
  conversation.reload
  
  puts "📋 CURRENT DATA FOR CONVERSATION 1987:"
  puts "  - Contact: #{conversation.contact.name}"
  puts "  - Phone: #{conversation.contact.phone_number}"
  puts "  - Source ID: #{conversation.contact_inbox.source_id}"
  puts
  
  # Check if this is actually Witalo's conversation
  witalo_phone = "558597550136"
  is_witalo = conversation.contact.phone_number&.include?(witalo_phone) || 
              conversation.contact_inbox.source_id&.include?(witalo_phone)
  
  if is_witalo
    puts "✅ Conversation 1987 IS Witalo's conversation"
    puts "   The system should work correctly now"
  else
    puts "❌ Conversation 1987 is NOT Witalo's conversation"
    puts "   Looking for Witalo's actual conversation..."
    
    # Find Witalo's real conversation
    witalo_contact_inboxes = ContactInbox.where("source_id LIKE ?", "%#{witalo_phone}%")
    
    if witalo_contact_inboxes.any?
      witalo_contact_inboxes.each do |ci|
        conversations = Conversation.where(contact_inbox_id: ci.id)
                                  .where(account_id: 3, inbox_id: 4)
                                  .order(updated_at: :desc)
        
        if conversations.any?
          latest_conv = conversations.first
          puts "🎯 Found Witalo's conversation:"
          puts "   - Conversation ID: #{latest_conv.id}"
          puts "   - Contact: #{latest_conv.contact.name}"
          puts "   - Phone: #{latest_conv.contact.phone_number}"
          puts "   - Source ID: #{latest_conv.contact_inbox.source_id}"
          puts "   - Status: #{latest_conv.status}"
          puts "   - Last Updated: #{latest_conv.updated_at}"
          puts
          puts "💡 USE CONVERSATION ID #{latest_conv.id} FOR WITALO!"
        end
      end
    else
      puts "❌ No contact_inbox found for Witalo's phone number"
    end
  end

rescue => e
  puts "❌ Error: #{e.message}"
  puts e.backtrace.first(5).join("\n")
end

puts
puts "🏁 Fix attempt completed"