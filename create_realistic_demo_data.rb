#!/usr/bin/env ruby
# Create Realistic Demo Data - Makes Chatwoot look like a fully functional platform
# Run with: bin/rails runner create_realistic_demo_data.rb

puts "\n"
puts '=' * 80
puts '🎬 CREATING REALISTIC DEMO DATA FOR CHATWOOT'
puts '=' * 80
puts "\n"

account = Account.first
user = account.users.first

# Ensure we have an inbox
inbox = account.inboxes.first || begin
  puts '📥 Creating inbox...'
  channel = Channel::WebWidget.create!(
    account: account,
    website_url: 'https://acmecorp.com',
    widget_color: '#1f93ff'
  )
  Inbox.create!(
    account: account,
    name: 'Website Support',
    channel: channel
  )
end

puts "✅ Using inbox: #{inbox.name}"
puts ''

# Create realistic customer profiles
customers = [
  {
    name: 'Sarah Mitchell',
    email: 'sarah.mitchell@techstartup.io',
    company: 'TechStartup Inc',
    phone: '+14155551001',
    conversations: [
      {
        messages: [
          { content: "URGENT! Our payment processing is completely broken. We're losing sales!", sentiment: 'negative', incoming: true },
          { content: 'I understand this is critical. Let me investigate immediately.', sentiment: 'neutral', incoming: false },
          { content: "We've lost $5000 in sales in the last hour!", sentiment: 'negative', incoming: true }
        ],
        status: :open,
        priority: 'critical',
        created_hours_ago: 2
      }
    ]
  },
  {
    name: 'Michael Chen',
    email: 'm.chen@globalenterprises.com',
    company: 'Global Enterprises',
    phone: '+14155551002',
    conversations: [
      {
        messages: [
          { content: "Hi, I'm interested in upgrading to your Enterprise plan. Can you help?", sentiment: 'positive', incoming: true },
          { content: "Absolutely! I'd be happy to help you with that. Let me get some details.", sentiment: 'positive', incoming: false },
          { content: 'We have about 50 agents and need advanced analytics.', sentiment: 'neutral', incoming: true },
          { content: 'Perfect! Our Enterprise plan includes unlimited agents and advanced analytics.', sentiment: 'positive', incoming: false }
        ],
        status: :open,
        priority: 'elevated',
        created_hours_ago: 5
      },
      {
        messages: [
          { content: "Thanks for the demo yesterday! We're ready to proceed.", sentiment: 'positive', incoming: true },
          { content: "Wonderful! I'll send over the contract details right away.", sentiment: 'positive', incoming: false }
        ],
        status: :resolved,
        priority: 'normal',
        created_hours_ago: 48
      }
    ]
  },
  {
    name: 'Emily Rodriguez',
    email: 'emily.r@designstudio.co',
    company: 'Creative Design Studio',
    phone: '+14155551003',
    conversations: [
      {
        messages: [
          { content: 'The dashboard is not loading. I keep getting error messages.', sentiment: 'negative', incoming: true },
          { content: "I'm sorry to hear that. Can you tell me what error message you're seeing?", sentiment: 'neutral', incoming: false },
          { content: "It says 'Failed to load data' and then the page goes blank.", sentiment: 'negative', incoming: true },
          { content: 'Thank you for that information. Let me check our system status.', sentiment: 'neutral', incoming: false }
        ],
        status: :open,
        priority: 'high_priority',
        created_hours_ago: 3
      }
    ]
  },
  {
    name: 'David Park',
    email: 'david.park@retailcorp.com',
    company: 'RetailCorp',
    phone: '+14155551004',
    conversations: [
      {
        messages: [
          { content: 'Quick question about your API rate limits', sentiment: 'neutral', incoming: true },
          { content: 'Sure! Our API allows 1000 requests per hour on the Pro plan.', sentiment: 'neutral', incoming: false },
          { content: 'Perfect, that should work for us. Thanks!', sentiment: 'positive', incoming: true }
        ],
        status: :resolved,
        priority: 'normal',
        created_hours_ago: 24
      }
    ]
  },
  {
    name: 'Jennifer Thompson',
    email: 'j.thompson@financialservices.com',
    company: 'Financial Services Ltd',
    phone: '+14155551005',
    conversations: [
      {
        messages: [
          { content: "I'm very disappointed with the service. This is the third time I've had issues.", sentiment: 'negative', incoming: true },
          { content: 'I sincerely apologize for the frustration. Let me escalate this to our senior team.', sentiment: 'neutral', incoming: false },
          { content: "I need this resolved ASAP or I'll have to cancel my subscription.", sentiment: 'negative', incoming: true }
        ],
        status: :open,
        priority: 'critical',
        created_hours_ago: 1
      }
    ]
  },
  {
    name: 'Robert Anderson',
    email: 'robert.a@healthtech.io',
    company: 'HealthTech Solutions',
    phone: '+14155551006',
    conversations: [
      {
        messages: [
          { content: 'How do I export my conversation history?', sentiment: 'neutral', incoming: true },
          { content: 'You can export conversations from Settings > Data Export. Would you like me to guide you?', sentiment: 'neutral',
            incoming: false },
          { content: 'Yes please, that would be helpful.', sentiment: 'positive', incoming: true },
          { content: 'Great! First, go to Settings in the left sidebar...', sentiment: 'positive', incoming: false }
        ],
        status: :open,
        priority: 'normal',
        created_hours_ago: 6
      }
    ]
  },
  {
    name: 'Lisa Wang',
    email: 'lisa.wang@ecommerce.shop',
    company: 'E-Commerce Shop',
    phone: '+14155551007',
    conversations: [
      {
        messages: [
          { content: 'Your platform is amazing! Just wanted to say thanks for the great support.', sentiment: 'positive', incoming: true },
          { content: "Thank you so much for the kind words! We're here whenever you need us.", sentiment: 'positive', incoming: false }
        ],
        status: :resolved,
        priority: 'normal',
        created_hours_ago: 72
      },
      {
        messages: [
          { content: 'Can I add custom fields to the contact form?', sentiment: 'neutral', incoming: true },
          { content: 'Yes! You can add custom attributes in Settings > Custom Attributes.', sentiment: 'neutral', incoming: false },
          { content: 'Excellent, found it. Thanks!', sentiment: 'positive', incoming: true }
        ],
        status: :resolved,
        priority: 'normal',
        created_hours_ago: 96
      }
    ]
  },
  {
    name: 'James Wilson',
    email: 'james.w@consulting.biz',
    company: 'Wilson Consulting',
    phone: '+14155551008',
    conversations: [
      {
        messages: [
          { content: 'The mobile app keeps crashing when I try to send attachments.', sentiment: 'negative', incoming: true },
          { content: "I'm sorry about that. What type of files are you trying to attach?", sentiment: 'neutral', incoming: false },
          { content: 'PDF files, usually around 2-3 MB.', sentiment: 'neutral', incoming: true },
          { content: "That should work fine. Let me check if there's a known issue with the latest version.", sentiment: 'neutral', incoming: false }
        ],
        status: :open,
        priority: 'elevated',
        created_hours_ago: 4
      }
    ]
  },
  {
    name: 'Maria Garcia',
    email: 'maria.garcia@nonprofit.org',
    company: 'Community Nonprofit',
    phone: '+14155551009',
    conversations: [
      {
        messages: [
          { content: 'Do you offer discounts for nonprofit organizations?', sentiment: 'neutral', incoming: true },
          { content: 'Yes! We offer 50% off for verified nonprofits. I can help you apply.', sentiment: 'positive', incoming: false },
          { content: "That's wonderful! What documentation do you need?", sentiment: 'positive', incoming: true },
          { content: 'Just your 501(c)(3) certificate or equivalent. You can email it to nonprofits@chatwoot.com', sentiment: 'positive',
            incoming: false }
        ],
        status: :resolved,
        priority: 'normal',
        created_hours_ago: 120
      }
    ]
  },
  {
    name: 'Thomas Brown',
    email: 'thomas.brown@manufacturing.com',
    company: 'Brown Manufacturing',
    phone: '+14155551010',
    conversations: [
      {
        messages: [
          { content: 'CRITICAL: System is down! None of our agents can access the platform!', sentiment: 'negative', incoming: true },
          { content: "I'm escalating this to our engineering team immediately. Checking system status now.", sentiment: 'neutral', incoming: false },
          { content: 'We have 20 agents unable to work. This is costing us thousands!', sentiment: 'negative', incoming: true }
        ],
        status: :open,
        priority: 'critical',
        created_hours_ago: 0.5
      }
    ]
  }
]

puts "👥 Creating #{customers.size} realistic customers with conversations..."
puts ''

created_count = 0
conversation_count = 0
message_count = 0

customers.each_with_index do |customer_data, _index|
  # Create contact
  contact = Contact.create!(
    account: account,
    name: customer_data[:name],
    email: customer_data[:email],
    phone_number: customer_data[:phone],
    additional_attributes: {
      company_name: customer_data[:company],
      city: ['San Francisco', 'New York', 'London', 'Tokyo', 'Berlin'].sample,
      country: %w[USA UK Japan Germany].sample
    }
  )

  # Create contact inbox
  contact_inbox = ContactInbox.create!(
    contact: contact,
    inbox: inbox,
    source_id: "web_#{SecureRandom.hex(8)}"
  )

  created_count += 1

  # Create conversations
  customer_data[:conversations].each do |conv_data|
    conversation = Conversation.create!(
      account: account,
      inbox: inbox,
      contact: contact,
      contact_inbox: contact_inbox,
      status: conv_data[:status],
      assignee: user,
      created_at: Time.now - conv_data[:created_hours_ago].hours,
      updated_at: Time.now - (conv_data[:created_hours_ago] - 0.5).hours
    )

    conversation_count += 1

    # Create messages
    conv_data[:messages].each_with_index do |msg_data, msg_index|
      message = Message.create!(
        account: account,
        inbox: inbox,
        conversation: conversation,
        message_type: msg_data[:incoming] ? :incoming : :outgoing,
        content: msg_data[:content],
        sender: msg_data[:incoming] ? contact : user,
        created_at: conversation.created_at + (msg_index * 5).minutes
      )

      # Add sentiment
      if msg_data[:sentiment] == 'negative'
        message.update_column(:sentiment, { label: 'negative', score: 0.85 }.to_json)
      elsif msg_data[:sentiment] == 'positive'
        message.update_column(:sentiment, { label: 'positive', score: 0.9 }.to_json)
      else
        message.update_column(:sentiment, { label: 'neutral', score: 0.5 }.to_json)
      end

      message_count += 1
    end

    # Calculate priority
    service = ConversationPriorityService.new(conversation)
    service.calculate_and_update!
  end

  print '.'
rescue StandardError => e
  puts "\n⚠️  Error creating #{customer_data[:name]}: #{e.message}"
end

puts "\n"
puts ''
puts "✅ Created #{created_count} customers"
puts "✅ Created #{conversation_count} conversations"
puts "✅ Created #{message_count} messages"
puts ''

# Create canned responses
puts '📝 Creating canned responses...'
puts ''

canned_responses_data = [
  { short_code: 'welcome', content: 'Hello! Welcome to our support team. How can I assist you today?' },
  { short_code: 'urgent_ack',
    content: "I understand this is urgent. I'm prioritizing your issue and will resolve it immediately. Let me investigate right away." },
  { short_code: 'pricing_basic',
    content: "Thank you for your interest in our pricing! We offer three plans:\n\n• Basic: $29/month - Perfect for small teams (up to 5 agents)\n• Pro: $79/month - Great for growing teams (up to 20 agents)\n• Enterprise: Custom pricing - Unlimited agents with advanced features\n\nWhich plan interests you?" },
  { short_code: 'pricing_enterprise',
    content: "Our Enterprise plan includes:\n• Unlimited agents\n• Advanced analytics and reporting\n• Priority support (24/7)\n• Custom integrations\n• Dedicated account manager\n• SLA guarantees\n\nI'd love to schedule a demo to show you these features. When works best for you?" },
  { short_code: 'error_investigate',
    content: "I apologize for the error you're experiencing. Let me investigate this right away. Can you provide:\n\n1. What were you doing when the error occurred?\n2. What error message did you see?\n3. What browser/device are you using?\n\nThis will help me resolve it quickly." },
  { short_code: 'thanks_resolved', content: "Great! I'm glad we could resolve your issue. Is there anything else I can help you with today?" },
  { short_code: 'followup', content: 'I wanted to follow up on your previous inquiry. Has everything been working smoothly since we last spoke?' },
  { short_code: 'escalate',
    content: "I'm escalating this to our senior technical team right away. They'll reach out within the next hour with a solution. Thank you for your patience." },
  { short_code: 'api_docs',
    content: "You can find our complete API documentation at https://docs.chatwoot.com/api\n\nKey resources:\n• Authentication: /api/v1/auth\n• Conversations: /api/v1/conversations\n• Messages: /api/v1/messages\n• Rate limits: 1000 requests/hour (Pro), 5000/hour (Enterprise)\n\nNeed help with a specific endpoint?" },
  { short_code: 'export_data',
    content: "To export your data:\n\n1. Go to Settings (left sidebar)\n2. Click 'Data Export'\n3. Select date range\n4. Choose format (CSV or JSON)\n5. Click 'Export'\n\nYou'll receive an email with the download link within 5-10 minutes." },
  { short_code: 'mobile_app',
    content: "Our mobile apps are available for:\n\n📱 iOS: https://apps.apple.com/chatwoot\n🤖 Android: https://play.google.com/chatwoot\n\nFeatures include:\n• Real-time notifications\n• Offline message drafts\n• Voice messages\n• File attachments\n\nLet me know if you need help setting it up!" },
  { short_code: 'integration_help',
    content: "We integrate with many popular tools:\n\n• Slack - Real-time notifications\n• WhatsApp - Multi-channel support\n• Facebook Messenger - Social media integration\n• Zapier - Connect 3000+ apps\n• Webhooks - Custom integrations\n\nWhich integration are you interested in?" },
  { short_code: 'billing_question',
    content: "For billing questions, I can help with:\n\n• Viewing invoices\n• Updating payment method\n• Changing plans\n• Applying discounts\n• Cancellation (we'd hate to see you go!)\n\nWhat do you need help with?" },
  { short_code: 'nonprofit_discount',
    content: "We're proud to support nonprofits! We offer 50% off all plans for verified nonprofit organizations.\n\nTo apply:\n1. Email your 501(c)(3) certificate to nonprofits@chatwoot.com\n2. Include your account email\n3. We'll verify and apply the discount within 24 hours\n\nThank you for the important work you do!" },
  { short_code: 'system_status',
    content: "I'm checking our system status now...\n\nYou can always check real-time status at: https://status.chatwoot.com\n\nIf you're experiencing issues, please let me know:\n• What feature is affected?\n• When did it start?\n• Is it affecting all users or just you?\n\nThis helps us resolve it faster!" },
  { short_code: 'training_resources',
    content: "We have excellent training resources:\n\n📚 Documentation: https://docs.chatwoot.com\n🎥 Video tutorials: https://youtube.com/chatwoot\n💬 Community forum: https://community.chatwoot.com\n📧 Weekly webinars: Every Thursday at 2pm PT\n\nWould you like me to schedule a personalized training session for your team?" },
  { short_code: 'security_question',
    content: "Security is our top priority. We provide:\n\n🔒 SOC 2 Type II certified\n🔒 GDPR compliant\n🔒 End-to-end encryption\n🔒 2FA authentication\n🔒 Regular security audits\n🔒 Data residency options\n\nFor detailed security information, visit: https://chatwoot.com/security\n\nDo you have specific security requirements?" },
  { short_code: 'custom_attributes',
    content: "To add custom attributes:\n\n1. Go to Settings > Custom Attributes\n2. Click 'Add Custom Attribute'\n3. Choose type (Text, Number, Date, List)\n4. Set display name and key\n5. Save\n\nYou can then use these in:\n• Contact profiles\n• Conversation filters\n• Reports\n• API calls\n\nNeed help setting up specific attributes?" },
  { short_code: 'team_management',
    content: "For team management:\n\n👥 Add agents: Settings > Agents > Invite\n📊 Set permissions: Admin, Agent, or Custom roles\n📈 Track performance: Reports > Agent Performance\n⚙️ Configure workflows: Settings > Automation\n\nBest practices:\n• Use teams for organization\n• Set up round-robin assignment\n• Enable auto-assignment\n• Track response times\n\nWhat would you like to set up?" },
  { short_code: 'closing_positive',
    content: "Perfect! I'm so glad I could help. If you need anything else, don't hesitate to reach out. We're here 24/7!\n\nHave a wonderful day! 😊" }
]

canned_count = 0
canned_responses_data.each do |data|
  CannedResponse.create!(
    account: account,
    short_code: data[:short_code],
    content: data[:content]
  )
  canned_count += 1
  print '.'
rescue StandardError
  # Skip if already exists
end

puts "\n"
puts "✅ Created #{canned_count} canned responses"
puts ''

# Calculate all priorities
puts '🔄 Calculating conversation priorities...'
Conversation.where(account: account).find_each do |conv|
  ConversationPriorityService.new(conv).calculate_and_update!
  print '.'
end
puts "\n"
puts '✅ All priorities calculated'
puts ''

# Show statistics
puts '=' * 80
puts '📊 DEMO DATA STATISTICS'
puts '=' * 80
puts ''

total_contacts = account.contacts.count
total_conversations = account.conversations.count
total_messages = account.messages.count
total_canned = account.canned_responses.count

puts "👥 Contacts: #{total_contacts}"
puts "💬 Conversations: #{total_conversations}"
puts "   • Open: #{account.conversations.open.count}"
puts "   • Resolved: #{account.conversations.resolved.count}"
puts "📨 Messages: #{total_messages}"
puts "📝 Canned Responses: #{total_canned}"
puts ''

puts '🎯 Priority Distribution:'
Conversation.where(account: account).group(:priority_level).count.sort_by { |k, _v| -k }.each do |level, count|
  level_name = Conversation.priority_levels.key(level).to_s.titleize
  percentage = (count.to_f / total_conversations * 100).round(1)

  emoji = case level
          when 3 then '🔴'
          when 2 then '🟠'
          when 1 then '🟡'
          else '⚪'
          end

  puts "   #{emoji} #{level_name.ljust(15)} #{count} (#{percentage}%)"
end
puts ''

puts '😊 Sentiment Distribution:'
sentiment_counts = { positive: 0, neutral: 0, negative: 0 }
Message.where(account: account).where.not(sentiment: nil).find_each do |msg|
  sentiment = JSON.parse(msg.sentiment)
  label = sentiment['label'].to_sym
  sentiment_counts[label] += 1 if sentiment_counts.key?(label)
end

total_sentiment = sentiment_counts.values.sum
if total_sentiment > 0
  sentiment_counts.each do |label, count|
    percentage = (count.to_f / total_sentiment * 100).round(1)
    emoji = case label
            when :positive then '😊'
            when :neutral then '😐'
            when :negative then '😞'
            end
    puts "   #{emoji} #{label.to_s.capitalize.ljust(10)} #{count} (#{percentage}%)"
  end
else
  puts '   No sentiment data yet'
end
puts ''

puts '=' * 80
puts '✨ DEMO DATA CREATION COMPLETE!'
puts '=' * 80
puts ''
puts '🌐 Open Chatwoot: http://localhost:3000'
puts '📧 Login: gunveerkalsi@gmail.com'
puts '🔑 Password: Password123!'
puts ''
puts "🎯 What you'll see:"
puts "   • #{total_contacts} realistic customer profiles"
puts "   • #{total_conversations} conversations with priority badges"
puts "   • #{total_messages} messages with sentiment analysis"
puts "   • #{total_canned} canned responses ready for AI suggestions"
puts ''
puts '🚀 Your Chatwoot instance now looks like a fully active platform!'
puts ''
