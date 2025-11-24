#!/usr/bin/env ruby
# Simple Demo Data Creator - Bypasses callbacks to avoid Sidekiq issues
# Run with: bin/rails runner create_demo_data_simple.rb

puts "\n🎬 Creating realistic demo data...\n\n"

account = Account.first
user = account.users.first
inbox = account.inboxes.first

# We'll use direct database inserts to avoid callback issues

# Create realistic conversations directly in database
conversations_data = [
  {
    contact: { name: 'Sarah Mitchell', email: 'sarah.mitchell@techstartup.io', phone: '+14155551001' },
    messages: ["URGENT! Payment processing is broken. We're losing sales!", 'I understand this is critical. Investigating now.'],
    status: 'open', hours_ago: 2, priority_score: 92.5, priority_level: 3
  },
  {
    contact: { name: 'Michael Chen', email: 'm.chen@globalenterprises.com', phone: '+14155551002' },
    messages: ['Interested in upgrading to Enterprise plan. Can you help?', 'Absolutely! Let me get some details.'],
    status: 'open', hours_ago: 5, priority_score: 55.0, priority_level: 1
  },
  {
    contact: { name: 'Emily Rodriguez', email: 'emily.r@designstudio.co', phone: '+14155551003' },
    messages: ['Dashboard not loading. Getting error messages.', 'Sorry to hear that. What error do you see?'],
    status: 'open', hours_ago: 3, priority_score: 72.0, priority_level: 2
  },
  {
    contact: { name: 'David Park', email: 'david.park@retailcorp.com', phone: '+14155551004' },
    messages: ['Quick question about API rate limits', 'Our API allows 1000 requests/hour on Pro plan.'],
    status: 'resolved', hours_ago: 24, priority_score: 25.0, priority_level: 0
  },
  {
    contact: { name: 'Jennifer Thompson', email: 'j.thompson@financialservices.com', phone: '+14155551005' },
    messages: ['Very disappointed. Third time having issues!', 'I sincerely apologize. Escalating to senior team.'],
    status: 'open', hours_ago: 1, priority_score: 88.0, priority_level: 3
  },
  {
    contact: { name: 'Robert Anderson', email: 'robert.a@healthtech.io', phone: '+14155551006' },
    messages: ['How do I export conversation history?', 'Go to Settings > Data Export. I can guide you.'],
    status: 'open', hours_ago: 6, priority_score: 30.0, priority_level: 0
  },
  {
    contact: { name: 'Lisa Wang', email: 'lisa.wang@ecommerce.shop', phone: '+14155551007' },
    messages: ['Platform is amazing! Thanks for great support.', "Thank you! We're here whenever you need us."],
    status: 'resolved', hours_ago: 72, priority_score: 15.0, priority_level: 0
  },
  {
    contact: { name: 'James Wilson', email: 'james.w@consulting.biz', phone: '+14155551008' },
    messages: ['Mobile app crashes when sending attachments.', 'Sorry about that. What file types are you attaching?'],
    status: 'open', hours_ago: 4, priority_score: 48.0, priority_level: 1
  },
  {
    contact: { name: 'Maria Garcia', email: 'maria.garcia@nonprofit.org', phone: '+14155551009' },
    messages: ['Do you offer nonprofit discounts?', 'Yes! 50% off for verified nonprofits.'],
    status: 'resolved', hours_ago: 120, priority_score: 20.0, priority_level: 0
  },
  {
    contact: { name: 'Thomas Brown', email: 'thomas.brown@manufacturing.com', phone: '+14155551010' },
    messages: ["CRITICAL: System down! 20 agents can't access platform!", 'Escalating to engineering immediately!'],
    status: 'open', hours_ago: 0.5, priority_score: 95.0, priority_level: 3
  }
]

created = 0
conversations_data.each do |data|
  # Create contact
  contact = Contact.find_or_create_by!(
    account: account,
    email: data[:contact][:email]
  ) do |c|
    c.name = data[:contact][:name]
    c.phone_number = data[:contact][:phone]
  end

  # Create contact inbox
  contact_inbox = ContactInbox.find_or_create_by!(
    contact: contact,
    inbox: inbox
  ) do |ci|
    ci.source_id = "web_#{SecureRandom.hex(8)}"
  end

  # Create conversation using raw SQL to bypass all callbacks
  conv_time = Time.now - data[:hours_ago].hours
  conv_time_str = conv_time.strftime('%Y-%m-%d %H:%M:%S')

  # Convert status string to integer (open: 0, resolved: 1)
  status_int = data[:status] == 'open' ? 0 : 1

  # Insert conversation directly
  result = ActiveRecord::Base.connection.execute(<<-SQL)
    INSERT INTO conversations (
      account_id, inbox_id, contact_id, contact_inbox_id, status, assignee_id,
      priority_score, priority_level, priority_factors,
      created_at, updated_at, display_id, uuid
    ) VALUES (
      #{account.id}, #{inbox.id}, #{contact.id}, #{contact_inbox.id},
      #{status_int}, #{user.id},
      #{data[:priority_score]}, #{data[:priority_level]},
      '{"sentiment_score": #{rand(0.0..1.0).round(2)}, "sla_score": #{rand(0.0..1.0).round(2)}}',
      '#{conv_time_str}', '#{conv_time_str}',
      #{account.conversations.maximum(:display_id).to_i + 1},
      '#{SecureRandom.uuid}'
    ) RETURNING id
  SQL

  conversation_id = result.first['id']

  # Create messages using raw SQL
  data[:messages].each_with_index do |content, idx|
    is_incoming = idx.even?
    msg_time = conv_time + (idx * 5).minutes
    msg_time_str = msg_time.strftime('%Y-%m-%d %H:%M:%S')
    sender_type = is_incoming ? 'Contact' : 'User'
    sender_id = is_incoming ? contact.id : user.id
    message_type = is_incoming ? 1 : 0

    ActiveRecord::Base.connection.execute(<<-SQL)
      INSERT INTO messages (
        account_id, inbox_id, conversation_id, message_type, content,
        sender_type, sender_id, created_at, updated_at
      ) VALUES (
        #{account.id}, #{inbox.id}, #{conversation_id}, #{message_type},
        #{ActiveRecord::Base.connection.quote(content)},
        '#{sender_type}', #{sender_id},
        '#{msg_time_str}', '#{msg_time_str}'
      )
    SQL
  end

  created += 1
  print '.'
end

puts "\n\n✅ Created #{created} realistic conversations with messages\n\n"

# Show final statistics
puts '=' * 60
puts '📊 DEMO DATA STATISTICS'
puts '=' * 60
puts ''
puts "👥 Total Contacts: #{account.contacts.count}"
puts "💬 Total Conversations: #{account.conversations.count}"
puts "   • Open: #{account.conversations.where(status: 'open').count}"
puts "   • Resolved: #{account.conversations.where(status: 'resolved').count}"
puts "📨 Total Messages: #{account.messages.count}"
puts "📝 Canned Responses: #{account.canned_responses.count}"
puts ''

puts '🎯 Priority Distribution:'
{ 3 => '🔴 Critical', 2 => '🟠 High', 1 => '🟡 Elevated', 0 => '⚪ Normal' }.each do |level, label|
  count = account.conversations.where(priority_level: level).count
  puts "   #{label.ljust(20)} #{count}" if count > 0
end
puts ''

puts '=' * 60
puts '✨ DEMO READY!'
puts '=' * 60
puts ''
puts '🌐 Open: http://localhost:3000'
puts '📧 Login: gunveerkalsi@gmail.com'
puts '🔑 Password: Password123!'
puts ''
puts '🎯 You now have a fully functional demo with:'
puts '   • Realistic customer conversations'
puts '   • Priority scores and badges'
puts '   • Mix of open and resolved tickets'
puts '   • Critical, high, and normal priority items'
puts ''
