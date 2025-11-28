# rubocop:disable Metrics/BlockLength
namespace :search do
  desc 'Create test messages for advanced search manual testing across multiple inboxes'
  task setup_test_data: :environment do
    puts '🔍 Setting up test data for advanced search...'

    account = Account.first
    unless account
      puts '❌ No account found. Please create an account first.'
      exit 1
    end

    agents = account.users.to_a
    unless agents.any?
      puts '❌ No agents found. Please create users first.'
      exit 1
    end

    puts "✅ Using account: #{account.name} (ID: #{account.id})"
    puts "✅ Found #{agents.count} agent(s)"

    # Create missing inbox types for comprehensive testing
    puts "\n📥 Checking and creating inboxes..."

    # API inbox
    unless account.inboxes.exists?(channel_type: 'Channel::Api')
      puts '  Creating API inbox...'
      account.inboxes.create!(
        name: 'Search Test API',
        channel: Channel::Api.create!(account: account)
      )
    end

    # Web Widget inbox
    unless account.inboxes.exists?(channel_type: 'Channel::WebWidget')
      puts '  Creating WebWidget inbox...'
      account.inboxes.create!(
        name: 'Search Test WebWidget',
        channel: Channel::WebWidget.create!(account: account, website_url: 'https://example.com')
      )
    end

    # Email inbox
    unless account.inboxes.exists?(channel_type: 'Channel::Email')
      puts '  Creating Email inbox...'
      account.inboxes.create!(
        name: 'Search Test Email',
        channel: Channel::Email.create!(
          account: account,
          email: 'search-test@example.com',
          imap_enabled: false,
          smtp_enabled: false
        )
      )
    end

    inboxes = account.inboxes.to_a
    puts "✅ Using #{inboxes.count} inbox(es):"
    inboxes.each { |i| puts "   - #{i.name} (ID: #{i.id}, Type: #{i.channel_type})" }

    # Create 10 test contacts
    contacts = []
    10.times do |i|
      contacts << account.contacts.find_or_create_by!(
        email: "test-customer-#{i}@example.com"
      ) do |c|
        c.name = Faker::Name.name
      end
    end
    puts "✅ Created/found #{contacts.count} test contacts"

    target_messages = 50_000
    messages_per_conversation = 100
    total_conversations = target_messages / messages_per_conversation

    puts "\n📝 Creating #{target_messages} messages across #{total_conversations} conversations..."
    puts "   Distribution: #{inboxes.count} inboxes × #{total_conversations / inboxes.count} conversations each"

    start_time = 2.years.ago
    end_time = Time.current
    time_range = end_time - start_time

    created_count = 0
    failed_count = 0
    conversations_per_inbox = total_conversations / inboxes.count
    conversation_statuses = [:open, :resolved]

    inboxes.each do |inbox|
      conversations_per_inbox.times do
        # Pick random contact and agent for this conversation
        contact = contacts.sample
        agent = agents.sample

        # Create or find ContactInbox
        contact_inbox = ContactInbox.find_or_create_by!(
          contact: contact,
          inbox: inbox
        ) do |ci|
          ci.source_id = "test_#{SecureRandom.hex(8)}"
        end

        # Create conversation
        conversation = inbox.conversations.create!(
          account: account,
          contact: contact,
          inbox: inbox,
          contact_inbox: contact_inbox,
          status: conversation_statuses.sample
        )

        # Create messages for this conversation (50 incoming, 50 outgoing)
        50.times do
          random_time = start_time + (rand * time_range)

          # Incoming message from contact
          begin
            Message.create!(
              content: Faker::Movie.quote,
              account: account,
              inbox: inbox,
              conversation: conversation,
              message_type: :incoming,
              sender: contact,
              created_at: random_time,
              updated_at: random_time
            )
            created_count += 1
          rescue StandardError => e
            failed_count += 1
            puts "❌ Failed to create message: #{e.message}" if failed_count <= 5
          end

          # Outgoing message from agent
          begin
            Message.create!(
              content: Faker::Movie.quote,
              account: account,
              inbox: inbox,
              conversation: conversation,
              message_type: :outgoing,
              sender: agent,
              created_at: random_time + rand(60..600),
              updated_at: random_time + rand(60..600)
            )
            created_count += 1
          rescue StandardError => e
            failed_count += 1
            puts "❌ Failed to create message: #{e.message}" if failed_count <= 5
          end

          print "\r🔄 Progress: #{created_count}/#{target_messages} messages created..." if (created_count % 500).zero?
        end
      end
    end

    puts "\n\n✅ Successfully created #{created_count} messages!"
    puts "❌ Failed: #{failed_count}" if failed_count.positive?

    puts "\n📊 Summary:"
    puts "  - Total messages: #{Message.where(account: account).count}"
    puts "  - Total conversations: #{Conversation.where(account: account).count}"

    min_date = Message.where(account: account).minimum(:created_at)&.strftime('%Y-%m-%d')
    max_date = Message.where(account: account).maximum(:created_at)&.strftime('%Y-%m-%d')
    puts "  - Date range: #{min_date} to #{max_date}"
    puts "\nBreakdown by inbox:"
    inboxes.each do |inbox|
      msg_count = Message.where(inbox: inbox).count
      conv_count = Conversation.where(inbox: inbox).count
      puts "  - #{inbox.name} (#{inbox.channel_type}): #{msg_count} messages, #{conv_count} conversations"
    end
    puts "\nBreakdown by sender type:"
    puts "  - Incoming (from contacts): #{Message.where(account: account, message_type: :incoming).count}"
    puts "  - Outgoing (from agents): #{Message.where(account: account, message_type: :outgoing).count}"

    puts "\n🔧 Next steps:"
    puts '  1. Ensure OpenSearch is running: mise elasticsearch-start'
    puts '  2. Reindex messages: rails runner "Message.search_index.import Message.all"'
    puts "  3. Enable feature: rails runner \"Account.find(#{account.id}).enable_features('advanced_search')\""
    puts "\n💡 Then test the search with filters via API or Rails console!"
  end
end
# rubocop:enable Metrics/BlockLength
