# frozen_string_literal: true

# Shared test helpers for Assignment v2 feature testing
#
# Key Design Decisions & Fixes:
#
# 1. Password Requirements:
#    - Users require complex passwords: 'Password123!' (uppercase + special char)
#
# 2. Unique Naming:
#    - All entities (inboxes, policies, agents) get unique names using SecureRandom.hex(4)
#    - Prevents validation errors across multiple test runs
#
# 3. Conversation Creation:
#    - Uses FactoryBot to handle complex associations automatically
#    - ContactInbox requires source_id (cannot be blank)
#    - FactoryBot factory handles: contact → contact_inbox → conversation chain
#
# 4. Policy Linking:
#    - RateLimiter reads from inbox.auto_assignment_config (not policy directly)
#    - link_policy_to_inbox syncs policy settings to inbox config
#    - Must call inbox.reload after linking to pick up association
#
# 5. Redis Access:
#    - Use Redis::Alfred.keys_count() instead of Redis::Alfred.redis.keys.count
#    - Use Redis::Alfred.scan_each() instead of Redis::Alfred.redis.keys for cleanup
#
# 6. Assignment Job:
#    - Must use keyword argument: perform_now(inbox_id: id)
#    - Not positional: perform_now(id) will fail
#
module AssignmentV2TestHelpers
  # Default test account ID
  DEFAULT_ACCOUNT_ID = 2

  # Color codes for terminal output
  COLORS = {
    green: "\e[32m",
    red: "\e[31m",
    yellow: "\e[33m",
    blue: "\e[34m",
    reset: "\e[0m"
  }.freeze

  def log(msg, prefix: '==>', color: nil)
    colored_prefix = color ? "#{COLORS[color]}#{prefix}#{COLORS[:reset]}" : prefix
    puts "\n#{colored_prefix} #{msg}"
  end

  def success(msg)
    log(msg, prefix: '✓', color: :green)
  end

  def error(msg)
    log(msg, prefix: '✗', color: :red)
  end

  def warning(msg)
    log(msg, prefix: '⚠', color: :yellow)
  end

  def info(msg)
    log(msg, prefix: 'ℹ', color: :blue)
  end

  def section(title)
    puts "\n#{'=' * 60}"
    puts "  #{title}"
    puts '=' * 60
  end

  def assert(condition, success_msg, error_msg)
    if condition
      success(success_msg)
      true
    else
      error(error_msg)
      false
    end
  end

  def assert_equal(actual, expected, description)
    if actual == expected
      success("#{description}: #{actual}")
      true
    else
      error("#{description}: Expected #{expected}, got #{actual}")
      false
    end
  end

  def get_test_account
    account = Account.find_by(id: DEFAULT_ACCOUNT_ID)
    raise "Account #{DEFAULT_ACCOUNT_ID} not found. Please create it first." unless account

    # Enable assignment_v2 feature
    account.enable_features('assignment_v2')
    account
  end

  def create_test_inbox(account, name: 'Test Inbox')
    unique_name = "#{name} #{SecureRandom.hex(4)}"

    channel = Channel::WebWidget.create!(
      account: account,
      website_url: 'https://test.com',
      widget_color: '#0000FF'
    )

    inbox = account.inboxes.create!(
      name: unique_name,
      channel: channel,
      enable_auto_assignment: true
    )

    info("Created inbox: #{inbox.name} (ID: #{inbox.id})")
    inbox
  end

  def create_test_policy(account, **options)
    defaults = {
      name: 'Test Policy',
      conversation_priority: 'earliest_created',
      enabled: true
    }

    merged_options = defaults.merge(options)
    # Always make name unique
    merged_options[:name] = "#{merged_options[:name]} #{SecureRandom.hex(4)}"

    policy = account.assignment_policies.create!(merged_options)
    info("Created policy: #{policy.name} (ID: #{policy.id})")
    policy
  end

  def link_policy_to_inbox(inbox, policy)
    InboxAssignmentPolicy.find_or_create_by!(
      inbox: inbox,
      assignment_policy: policy
    )

    # Also set inbox config for rate limiter (RateLimiter reads from inbox.auto_assignment_config)
    inbox.update!(
      auto_assignment_config: {
        'fair_distribution_limit' => policy.fair_distribution_limit,
        'fair_distribution_window' => policy.fair_distribution_window,
        'conversation_priority' => policy.conversation_priority
      }.compact
    )

    inbox.reload  # Reload to pick up the association
    info("Linked policy #{policy.id} to inbox #{inbox.id}")
    inbox
  end

  def create_test_agent(account, inbox, name:, email: nil, online: true)
    unique_id = SecureRandom.hex(4)
    email ||= "#{name.downcase.tr(' ', '_')}_#{unique_id}@test.com"
    unique_name = "#{name} #{unique_id}"

    user = account.users.create!(
      email: email,
      password: 'Password123!',
      password_confirmation: 'Password123!',
      name: unique_name,
      confirmed_at: Time.zone.now
    )

    # Add to inbox
    inbox.inbox_members.create!(user: user)

    # Set online status
    # Note: inbox.available_agents filters by status == 'online', so we set both presence and status
    if online
      OnlineStatusTracker.update_presence(account.id, 'User', user.id)
      OnlineStatusTracker.set_status(account.id, user.id, 'online')
    else
      # For offline agents, set status to 'offline' (they won't be in available_agents)
      OnlineStatusTracker.set_status(account.id, user.id, 'offline')
    end

    info("Created agent: #{user.name} (#{user.email}, online: #{online})")
    user
  end

  def create_test_conversation(inbox, **options)
    contact_name = options.delete(:contact_name) || "Customer #{SecureRandom.hex(4)}"

    # Use FactoryBot if available
    if defined?(FactoryBot)
      FactoryBot.create(
        :conversation,
        options.merge(
          inbox: inbox,
          account: inbox.account,
          contact: FactoryBot.create(:contact, account: inbox.account, name: contact_name)
        )
      )
    else
      # Fallback to manual creation
      defaults = {
        status: 'open',
        assignee_id: nil,
        created_at: Time.zone.now,
        last_activity_at: Time.zone.now
      }

      contact = inbox.contacts.create!(
        account: inbox.account,
        name: contact_name
      )

      contact_inbox = ContactInbox.create!(
        contact: contact,
        inbox: inbox,
        source_id: "test_#{SecureRandom.uuid}"
      )

      inbox.conversations.create!(
        defaults.merge(options).merge(
          account: inbox.account,
          contact: contact,
          contact_inbox: contact_inbox
        )
      )
    end
  end

  def create_bulk_conversations(inbox, count:, **options)
    conversations = count.times.map do |i|
      create_test_conversation(
        inbox,
        **options, contact_name: "Customer #{i + 1}",
                   created_at: (count - i).minutes.ago,
                   last_activity_at: options[:last_activity_at] || (count - i).minutes.ago
      )
    end

    info("Created #{count} test conversations")
    conversations
  end

  def run_assignment(inbox)
    info("Running assignment job for inbox #{inbox.id}...")
    before_count = inbox.conversations.unassigned.count

    AutoAssignment::AssignmentJob.perform_now(inbox_id: inbox.id)

    after_count = inbox.conversations.unassigned.count
    assigned_count = before_count - after_count
    info("Assigned: #{assigned_count} conversations (#{before_count} → #{after_count} unassigned)")

    assigned_count
  end

  def show_assignment_distribution(inbox, agents)
    log('Assignment Distribution:', color: :blue)
    agents.each do |agent|
      count = inbox.conversations.where(assignee: agent, status: 'open').count
      puts "  #{agent.name}: #{count} conversations"
    end

    unassigned = inbox.conversations.unassigned.count
    puts "  Unassigned: #{unassigned} conversations"
  end

  def count_redis_keys(pattern)
    Redis::Alfred.keys_count(pattern)
  end

  def cleanup_redis_keys(pattern)
    # Use scan to avoid blocking Redis with KEYS command
    Redis::Alfred.scan_each(match: pattern) do |key|
      Redis::Alfred.del(key)
    end
  end

  def cleanup_test_data(account, inbox: nil)
    if inbox
      info("Cleaning up inbox #{inbox.id}...")
      inbox.conversations.destroy_all
      inbox.inbox_members.destroy_all
      InboxAssignmentPolicy.where(inbox: inbox).destroy_all
      inbox.destroy
    else
      info("Cleaning up account #{account.id} test data...")
      account.conversations.where('created_at > ?', 1.hour.ago).destroy_all
      account.inbox_members.joins(:user).where(users: { email: [/.+@test\.com/] }).destroy_all
      account.inboxes.where('name LIKE ?', '%Test%').destroy_all
      account.assignment_policies.where('name LIKE ?', '%Test%').destroy_all
      account.users.where('email LIKE ?', '%@test.com%').destroy_all
    end
    success('Cleanup complete')
  end

  def enterprise_available?
    defined?(Enterprise)
  end

  def skip_if_not_enterprise
    return if enterprise_available?

    warning('Enterprise features not available, skipping test')
    exit(0)
  end
end
