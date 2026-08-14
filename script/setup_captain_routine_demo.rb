# Usage: ACCOUNT_ID=1 bundle exec rails runner script/setup_captain_routine_demo.rb

class CaptainRoutineDemoSetup
  RESETTABLE_ASSOCIATIONS = %i[
    captain_routines automation_rules conversations contacts inboxes teams labels
  ].freeze
  DEMO_PASSWORD = 'Password1!'.freeze

  def perform
    ensure_development!
    account = select_account
    confirm_reset!(account)

    ActiveJob::Base.queue_adapter = :test
    reset_account(account)
    resources = create_resources(account)
    conversations = create_conversations(account, resources)
    print_summary(account, resources, conversations)
  end

  private

  def ensure_development!
    return if Rails.env.development?

    abort "Captain Routine demo setup only runs in development. Current environment: #{Rails.env}"
  end

  def select_account
    account_id = ENV['ACCOUNT_ID'].presence
    return Account.find(account_id) if account_id

    stage('ACCOUNTS', 'Select the dedicated account to reset')
    Account.active.order(:id).each { |account| puts "  #{account.id.to_s.rjust(4)}  #{account.name}" }
    Account.find(ask('Account ID'))
  rescue ActiveRecord::RecordNotFound
    abort "Account #{account_id.inspect} was not found."
  end

  def confirm_reset!(account)
    puts
    stage('WARNING', "This permanently resets demo data in #{account.name} (#{account.id}).")
    reset_counts(account).each { |label, count| puts "  #{label.to_s.tr('_', ' ').ljust(22)} #{count}" }
    puts '  Administrators and the account itself are preserved.'
    puts

    phrase = "RESET #{account.id}"
    abort 'Demo setup cancelled.' unless ask("Type #{phrase.inspect} to continue") == phrase
  end

  def reset_counts(account)
    RESETTABLE_ASSOCIATIONS.index_with { |association| account.public_send(association).count }
                           .merge(agent_memberships: account.account_users.agent.count)
  end

  def reset_account(account)
    stage('RESETTING', 'Removing existing Routines and operational support data…')
    RESETTABLE_ASSOCIATIONS.each { |association| account.public_send(association).destroy_all }
    account.account_users.agent.destroy_all
    stage('RESET', 'Account is ready for deterministic demo data.')
  end

  def create_resources(account)
    stage('RESOURCES', 'Creating inbox, team, agents, and label…')
    agents = {
      jithin: create_agent(account, name: 'Jithin', email: 'captain.demo.jithin@example.com'),
      maya: create_agent(account, name: 'Maya Rao', email: 'captain.demo.maya@example.com'),
      noah: create_agent(account, name: 'Noah Williams', email: 'captain.demo.noah@example.com')
    }
    inbox = create_inbox(account, agents.values)
    team = create_team(account, [agents.fetch(:maya), agents.fetch(:noah)])
    label = account.labels.create!(
      title: 'p0-needs-attention',
      description: 'Triggers the downstream incident automation in the Routine demo.'
    )

    { agents: agents, inbox: inbox, team: team, label: label }
  end

  def create_agent(account, name:, email:)
    user = User.find_or_initialize_by(email: email)
    user.assign_attributes(name: name, password: DEMO_PASSWORD)
    user.skip_confirmation!
    user.save!

    # Agents::DestroyJob clears this on removal, but jobs are stubbed out here, so a stale
    # row from an earlier run would collide with the notification settings unique index.
    account.notification_settings.where(user_id: user.id).destroy_all
    account.account_users.create!(user: user, role: :agent, availability: :online)
    user
  end

  def create_inbox(account, agents)
    channel = Channel::Api.create!(account: account)
    inbox = Inbox.create!(
      account: account,
      channel: channel,
      name: 'Support',
      timezone: account.reporting_timezone.presence || 'UTC',
      enable_auto_assignment: false
    )
    inbox.add_members(agents.map(&:id))
    inbox
  end

  def create_team(account, engineers)
    team = account.teams.create!(name: 'Engineering', allow_auto_assign: false)
    team.add_members(engineers.map(&:id))
    team
  end

  def create_conversations(account, resources)
    stage('CONVERSATIONS', 'Creating both Routine scenarios…')
    agents = resources.fetch(:agents)
    inbox = resources.fetch(:inbox)
    team = resources.fetch(:team)

    {
      engineering_urgent: create_engineering_urgent(account, inbox, team, agents.fetch(:maya)),
      engineering_non_urgent: create_engineering_non_urgent(account, inbox, team, agents.fetch(:noah)),
      snoozed_overdue: create_snoozed_overdue(account, inbox, agents.fetch(:jithin)),
      snoozed_deferred: create_snoozed_deferred(account, inbox, agents.fetch(:jithin))
    }
  end

  def create_engineering_urgent(account, inbox, team, engineer)
    create_conversation(
      account: account,
      inbox: inbox,
      contact_name: 'Elena Torres',
      contact_email: 'elena.messaging@example.com',
      assignee: engineer,
      team: team,
      scenario: 'engineering_urgent',
      messages: [
        incoming('Our agents can send messages, but customers are not receiving any of them. This is blocking our support team.', 6.hours.ago),
        outgoing('Thanks, Elena. I am checking the delivery logs and provider status now.', engineer, 5.hours.ago),
        incoming('It is still happening across every inbox. We cannot respond to customers at all.', 4.hours.ago)
      ]
    )
  end

  def create_engineering_non_urgent(account, inbox, team, engineer)
    create_conversation(
      account: account,
      inbox: inbox,
      contact_name: 'Marcus Chen',
      contact_email: 'marcus.reports@example.com',
      assignee: engineer,
      team: team,
      scenario: 'engineering_non_urgent',
      messages: [
        incoming('The CSV report exports correctly, but the date column is difficult to read. Can it use our account timezone?', 8.hours.ago),
        outgoing('Good suggestion. I have shared this with engineering and will update you after we review it.', engineer, 7.hours.ago),
        incoming('Thank you. This is not blocking us, so an update this week is fine.', 6.hours.ago)
      ]
    )
  end

  def create_snoozed_overdue(account, inbox, agent)
    conversation = create_conversation(
      account: account,
      inbox: inbox,
      contact_name: 'Nadia Silva',
      contact_email: 'nadia.logs@example.com',
      assignee: agent,
      scenario: 'snoozed_overdue',
      messages: [
        incoming('The widget sometimes disappears after I navigate between pages.', 5.days.ago),
        outgoing('Could you send the affected page URL and a browser console screenshot so we can investigate?', agent, 4.days.ago)
      ]
    )
    snooze(conversation, until_time: 2.days.from_now)
  end

  def create_snoozed_deferred(account, inbox, agent)
    conversation = create_conversation(
      account: account,
      inbox: inbox,
      contact_name: 'Owen Brooks',
      contact_email: 'owen.imports@example.com',
      assignee: agent,
      scenario: 'snoozed_deferred',
      messages: [
        incoming('I am travelling and will send the import file and error log next week.', 2.days.ago),
        outgoing('No problem, Owen. We will wait for the files and continue when you are back next week.', agent, 2.days.ago + 10.minutes)
      ]
    )
    snooze(conversation, until_time: 6.days.from_now)
  end

  def create_conversation(account:, inbox:, contact_name:, contact_email:, assignee:, scenario:, messages:, team: nil)
    contact = account.contacts.create!(name: contact_name, email: contact_email, identifier: "captain-demo-#{scenario}")
    contact_inbox = ContactInboxBuilder.new(contact: contact, inbox: inbox).perform
    created_at = messages.first.fetch(:created_at) - 10.minutes
    conversation = Conversation.create!(
      account: account,
      inbox: inbox,
      contact: contact,
      contact_inbox: contact_inbox,
      assignee: assignee,
      team: team,
      status: :open,
      created_at: created_at,
      last_activity_at: created_at,
      custom_attributes: { 'captain_routine_demo' => scenario }
    )
    messages.each { |message| create_message(conversation, message) }
    conversation.reload
  end

  def create_message(conversation, attributes)
    sender = attributes.fetch(:sender, conversation.contact)
    conversation.messages.create!(
      account: conversation.account,
      inbox: conversation.inbox,
      sender: sender,
      message_type: attributes.fetch(:message_type),
      content: attributes.fetch(:content),
      content_type: :text,
      private: false,
      created_at: attributes.fetch(:created_at),
      updated_at: attributes.fetch(:created_at)
    )
  end

  def incoming(content, created_at)
    { message_type: :incoming, content: content, created_at: created_at }
  end

  def outgoing(content, sender, created_at)
    { message_type: :outgoing, content: content, sender: sender, created_at: created_at }
  end

  def snooze(conversation, until_time:)
    conversation.update!(status: :snoozed, snoozed_until: until_time)
    conversation
  end

  def print_summary(account, resources, conversations)
    puts
    stage('READY', "Captain Routine demo data created for #{account.name} (#{account.id}).")
    puts "  Inbox                 #{resources.fetch(:inbox).name} (#{resources.fetch(:inbox).id})"
    puts "  Team                  #{resources.fetch(:team).name} (#{resources.fetch(:team).id})"
    puts "  Label                 #{resources.fetch(:label).title}"
    puts "  Agents                #{resources.fetch(:agents).values.map(&:name).join(', ')}"
    puts
    conversations.each do |scenario, conversation|
      puts "  #{scenario.to_s.ljust(24)} conversation ##{conversation.display_id} (ID #{conversation.id})"
    end
    puts
    puts 'Next:'
    puts "  ACCOUNT_ID=#{account.id} bundle exec rails runner script/create_captain_routine_examples.rb"
    puts "  ACCOUNT_ID=#{account.id} bundle exec rails runner script/run_captain_routine.rb"
  end

  def stage(label, message)
    puts "#{label.to_s.ljust(14)} #{message}"
  end

  def ask(question)
    print "? #{question} › "
    $stdout.flush
    answer = $stdin.gets
    abort '\nSetup cancelled because input was closed.' if answer.nil?

    answer.strip
  end
end

CaptainRoutineDemoSetup.new.perform unless ENV['SKIP_CAPTAIN_ROUTINE_DEMO_SETUP'] == 'true'
