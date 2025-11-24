#!/usr/bin/env ruby
# Setup comprehensive demo data for presentation
# Run with: bin/rails runner setup_demo_data.rb

puts '🎬 Setting up demo data for presentation...'
puts ''

account = Account.first
user = account.users.first

# Ensure we have an inbox
inbox = account.inboxes.first || begin
  puts '📥 Creating demo inbox...'
  channel = Channel::WebWidget.create!(
    account: account,
    website_url: 'https://demo.example.com',
    widget_color: '#1f93ff'
  )
  Inbox.create!(
    account: account,
    name: 'Demo Website Support',
    channel: channel
  )
end

puts "✅ Using inbox: #{inbox.name}"
puts ''

# Create diverse contacts with conversations
demo_scenarios = [
  {
    name: 'Sarah Johnson',
    email: 'sarah.johnson@example.com',
    message: 'URGENT! My payment failed and I need to access my account immediately. This is critical for my business!',
    sentiment: 'negative',
    priority: 'critical'
  },
  {
    name: 'Mike Chen',
    email: 'mike.chen@example.com',
    message: "Hi, I'm interested in upgrading to your premium plan. Can you tell me about the pricing?",
    sentiment: 'positive',
    priority: 'normal'
  },
  {
    name: 'Emily Rodriguez',
    email: 'emily.rodriguez@example.com',
    message: 'The app is not working properly. I keep getting error messages when I try to save.',
    sentiment: 'negative',
    priority: 'high'
  },
  {
    name: 'David Kim',
    email: 'david.kim@example.com',
    message: 'Thank you for the great support yesterday! Just wanted to follow up on one more question.',
    sentiment: 'positive',
    priority: 'normal'
  },
  {
    name: 'Lisa Anderson',
    email: 'lisa.anderson@example.com',
    message: 'ASAP: Need help with integration setup. Our team is blocked and cannot proceed!',
    sentiment: 'negative',
    priority: 'high'
  }
]

puts '👥 Creating demo contacts and conversations...'
puts ''

demo_scenarios.each_with_index do |scenario, index|
  # Create or find contact
  contact = Contact.find_or_create_by!(
    account: account,
    email: scenario[:email]
  ) do |c|
    c.name = scenario[:name]
  end

  # Create contact inbox
  contact_inbox = ContactInbox.find_or_create_by!(
    contact: contact,
    inbox: inbox
  ) do |ci|
    ci.source_id = SecureRandom.uuid
  end

  # Create conversation
  conversation = Conversation.create!(
    account: account,
    inbox: inbox,
    contact: contact,
    contact_inbox: contact_inbox,
    status: :open,
    assignee: user
  )

  # Create incoming message
  message = Message.create!(
    account: account,
    inbox: inbox,
    conversation: conversation,
    message_type: :incoming,
    content: scenario[:message],
    sender: contact,
    created_at: Time.now - (index * 10).minutes
  )

  # Add sentiment data if needed
  if scenario[:sentiment] == 'negative'
    message.update_column(:sentiment, { label: 'negative', score: 0.8 }.to_json)
  elsif scenario[:sentiment] == 'positive'
    message.update_column(:sentiment, { label: 'positive', score: 0.9 }.to_json)
  end

  # Calculate priority
  ConversationPriorityService.new(conversation).calculate_and_update!

  puts "  ✓ Created: #{scenario[:name]} - Priority: #{conversation.priority_level}"
end

puts ''
puts '📝 Creating canned responses...'

canned_responses_data = [
  { short_code: 'welcome', content: 'Hello! Welcome to our support team. How can I assist you today?' },
  { short_code: 'urgent', content: "I understand this is urgent. I'm prioritizing your issue and will resolve it immediately." },
  { short_code: 'pricing',
    content: "Thank you for your interest in our pricing! We offer several plans:\n- Basic: $29/month\n- Pro: $79/month\n- Enterprise: Custom pricing\n\nWhich plan interests you?" },
  { short_code: 'error',
    content: "I apologize for the error you're experiencing. Let me investigate this right away. Can you provide more details about when this started?" },
  { short_code: 'thanks', content: 'Thank you for reaching out! Is there anything else I can help you with today?' },
  { short_code: 'resolved', content: "Great! I'm glad we could resolve your issue. Feel free to contact us anytime if you need further assistance." },
  { short_code: 'followup', content: 'I wanted to follow up on your previous inquiry. Has everything been working smoothly?' }
]

canned_responses_data.each do |data|
  CannedResponse.find_or_create_by!(
    account: account,
    short_code: data[:short_code]
  ) do |cr|
    cr.content = data[:content]
  end
  puts "  ✓ Created: #{data[:short_code]}"
end

puts ''
puts '=' * 80
puts '✨ DEMO DATA SETUP COMPLETE!'
puts '=' * 80
puts ''
puts 'Summary:'
puts "  - Contacts: #{account.contacts.count}"
puts "  - Conversations: #{account.conversations.count}"
puts "  - Messages: #{account.messages.count}"
puts "  - Canned Responses: #{account.canned_responses.count}"
puts ''
puts '🎯 Next Steps:'
puts '  1. Open http://localhost:3000 in your browser'
puts '  2. Login with: gunveerkalsi@gmail.com / Password123!'
puts "  3. Navigate to 'Conversations' to see priority badges"
puts '  4. Click on any contact to see their details'
puts '  5. Use the API endpoints to show backend features'
puts ''
