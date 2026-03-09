#!/usr/bin/env ruby
# Debug script to investigate conversation 1987 data inconsistency

puts "🔍 Investigating Conversation 1987 Data Inconsistency"
puts "=" * 60

begin
  # Find conversation 1987
  conversation = Conversation.find(1987)
  
  puts "📋 CONVERSATION 1987 DETAILS:"
  puts "  - ID: #{conversation.id}"
  puts "  - Account ID: #{conversation.account_id}"
  puts "  - Inbox ID: #{conversation.inbox_id}"
  puts "  - Status: #{conversation.status}"
  puts "  - Created: #{conversation.created_at}"
  puts "  - Updated: #{conversation.updated_at}"
  puts

  # Check contact details
  contact = conversation.contact
  puts "👤 CONTACT DETAILS:"
  puts "  - Contact ID: #{contact.id}"
  puts "  - Name: #{contact.name}"
  puts "  - Phone: #{contact.phone_number}"
  puts "  - Email: #{contact.email}"
  puts

  # Check contact_inbox details
  contact_inbox = conversation.contact_inbox
  puts "📞 CONTACT_INBOX DETAILS:"
  puts "  - ContactInbox ID: #{contact_inbox.id}"
  puts "  - Source ID: #{contact_inbox.source_id}"
  puts "  - Inbox ID: #{contact_inbox.inbox_id}"
  puts "  - Contact ID: #{contact_inbox.contact_id}"
  puts

  # Check if there are multiple contact_inboxes for this contact
  all_contact_inboxes = ContactInbox.where(contact_id: contact.id)
  puts "🔗 ALL CONTACT_INBOXES FOR THIS CONTACT:"
  all_contact_inboxes.each do |ci|
    puts "  - ContactInbox ID: #{ci.id}, Source ID: #{ci.source_id}, Inbox ID: #{ci.inbox_id}"
  end
  puts

  # Check recent messages
  recent_messages = conversation.messages.order(created_at: :desc).limit(5)
  puts "💬 RECENT MESSAGES (last 5):"
  recent_messages.each do |msg|
    puts "  - ID: #{msg.id}, Type: #{msg.message_type}, Content: #{msg.content&.truncate(50)}, Created: #{msg.created_at}"
  end
  puts

  # Check if there's another conversation for Witalo
  puts "🔍 SEARCHING FOR WITALO'S CONVERSATIONS:"
  witalo_phone = "558597550136"
  
  # Search by phone number in contacts
  witalo_contacts = Contact.where("phone_number LIKE ?", "%#{witalo_phone}%")
  puts "  - Found #{witalo_contacts.count} contacts with phone like #{witalo_phone}"
  
  witalo_contacts.each do |contact|
    puts "    Contact ID: #{contact.id}, Name: #{contact.name}, Phone: #{contact.phone_number}"
    
    # Find conversations for this contact
    contact_conversations = Conversation.joins(:contact_inbox)
                                      .where(contact_inboxes: { contact_id: contact.id })
    
    puts "    Conversations for this contact:"
    contact_conversations.each do |conv|
      puts "      - Conversation ID: #{conv.id}, Status: #{conv.status}, Inbox: #{conv.inbox_id}"
    end
  end
  puts

  # Search by source_id in contact_inboxes
  witalo_contact_inboxes = ContactInbox.where("source_id LIKE ?", "%#{witalo_phone}%")
  puts "  - Found #{witalo_contact_inboxes.count} contact_inboxes with source_id like #{witalo_phone}"
  
  witalo_contact_inboxes.each do |ci|
    puts "    ContactInbox ID: #{ci.id}, Source ID: #{ci.source_id}, Contact ID: #{ci.contact_id}"
    
    # Find conversations for this contact_inbox
    ci_conversations = Conversation.where(contact_inbox_id: ci.id)
    puts "    Conversations for this contact_inbox:"
    ci_conversations.each do |conv|
      puts "      - Conversation ID: #{conv.id}, Status: #{conv.status}, Created: #{conv.created_at}"
    end
  end
  puts

  puts "🎯 SUMMARY:"
  puts "  - Conversation 1987 belongs to: #{contact.name} (#{contact.phone_number})"
  puts "  - ContactInbox source_id: #{contact_inbox.source_id}"
  puts "  - Expected Witalo phone: #{witalo_phone}"
  puts "  - Match: #{contact.phone_number&.include?(witalo_phone) || contact_inbox.source_id&.include?(witalo_phone)}"

rescue ActiveRecord::RecordNotFound => e
  puts "❌ Conversation 1987 not found: #{e.message}"
rescue => e
  puts "❌ Error: #{e.message}"
  puts e.backtrace.first(5).join("\n")
end

puts
puts "🏁 Investigation completed"