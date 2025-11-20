# rubocop:disable Metrics/BlockLength
namespace :search do
  desc 'Create test messages for advanced search manual testing'
  task setup_test_data: :environment do
    puts '🔍 Finding or creating test account, inbox, and users...'

    account = Account.first
    unless account
      puts '❌ No account found. Please create an account first.'
      exit 1
    end

    inbox = account.inboxes.where(channel_type: 'Channel::Api').first
    unless inbox
      puts '📥 Creating API inbox for test messages...'
      inbox = account.inboxes.create!(
        name: 'Search Test Inbox',
        channel_type: 'Channel::Api',
        channel: Channel::Api.create!(account: account)
      )
    end

    contact = account.contacts.find_or_create_by!(
      name: 'Test Customer',
      email: 'test-customer@example.com'
    )

    agent = account.users.first
    unless agent
      puts '❌ No agent found. Please create a user first.'
      exit 1
    end

    puts "✅ Using account: #{account.name} (ID: #{account.id})"
    puts "✅ Using inbox: #{inbox.name} (ID: #{inbox.id})"
    puts "✅ Using contact: #{contact.name} (ID: #{contact.id})"
    puts "✅ Using agent: #{agent.name} (ID: #{agent.id})"

    puts "\n📝 Creating 1000 messages (500 from contact, 500 from agent)..."

    start_time = 2.years.ago
    end_time = Time.current
    time_range = end_time - start_time

    created_count = 0
    failed_count = 0

    # Create ContactInbox to link contact to inbox
    contact_inbox = ContactInbox.find_or_create_by!(
      contact: contact,
      inbox: inbox
    ) do |ci|
      ci.source_id = "test_#{SecureRandom.hex(8)}"
    end

    conversation = inbox.conversations.create!(
      account: account,
      contact: contact,
      inbox: inbox,
      contact_inbox: contact_inbox,
      status: :open
    )

    # Create 500 incoming messages from contact using Faker movie quotes
    500.times do |i|
      content = Faker::Movie.quote
      random_time = start_time + (rand * time_range)

      begin
        Message.create!(
          content: content,
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
        puts "❌ Failed to create message #{i}: #{e.message}" if failed_count <= 5
      end

      print "\r🔄 Progress: #{created_count}/1000 messages created..." if (i % 50).zero?
    end

    # Create 500 outgoing messages from agent using Faker movie quotes
    500.times do |i|
      content = Faker::Movie.quote
      random_time = start_time + (rand * time_range)

      begin
        Message.create!(
          content: content,
          account: account,
          inbox: inbox,
          conversation: conversation,
          message_type: :outgoing,
          sender: agent,
          created_at: random_time,
          updated_at: random_time
        )
        created_count += 1
      rescue StandardError => e
        failed_count += 1
        puts "❌ Failed to create message #{i}: #{e.message}" if failed_count <= 5
      end

      print "\r🔄 Progress: #{created_count}/1000 messages created..." if (i % 50).zero?
    end

    puts "\n\n✅ Successfully created #{created_count} messages!"
    puts "❌ Failed: #{failed_count}" if failed_count.positive?

    puts "\n📊 Summary:"
    puts "  - Contact messages (incoming): #{Message.where(sender: contact).count}"
    puts "  - Agent messages (outgoing): #{Message.where(sender: agent).count}"
    puts "  - Date range: #{Message.minimum(:created_at)&.strftime('%Y-%m-%d')} to #{Message.maximum(:created_at)&.strftime('%Y-%m-%d')}"

    puts "\n🔧 Next steps:"
    puts '  1. Ensure Elasticsearch is running and OPENSEARCH_URL is set'
    puts '  2. Run: rails console'
    puts '  3. Run: Message.reindex'
    puts "  4. Enable feature: Account.first.enable_features('advanced_search')"
    puts "\n💡 Then test the search with filters in Rails console!"
  end
end
# rubocop:enable Metrics/BlockLength
