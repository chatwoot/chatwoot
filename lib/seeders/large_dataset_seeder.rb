# rubocop:disable all
require 'faker'

class Seeders::LargeDatasetSeeder
  # Constants for configuring the seeder
  TOTAL_CONVERSATIONS = 10_000
  TOTAL_CONTACTS = 1000
  TOTAL_AGENTS = 200
  TOTAL_TEAMS = 8
  TOTAL_LABELS = 100
  TOTAL_INBOXES = 3
  MESSAGES_PER_CONVERSATION = 5
  START_DATE = 1.year.ago
  END_DATE = Time.current

  def initialize(account:)
    raise 'Account Seeding is not allowed.' unless ENV.fetch('ENABLE_ACCOUNT_SEEDING', !Rails.env.production?)

    @account = account
    @teams = []
    @agents = []
    @labels = []
    @inboxes = []
    @contacts = []
    @priorities = [nil, 'urgent', 'high', 'medium', 'low']
  end

  def perform!
    puts "Starting large dataset seeding for account: #{@account.name}"

    # Clear existing data
    clear_existing_data

    # Create teams, agents, labels, inboxes, and contacts
    create_teams
    create_agents
    create_labels
    create_inboxes
    create_contacts

    # Create conversations with messages and labels
    create_conversations

    puts "Completed large dataset seeding for account: #{@account.name}"
  end

  private

  def clear_existing_data
    puts "Clearing existing data for account: #{@account.id}"

    # We're not actually deleting existing data in this seeder
    # as it might be dangerous. Instead, we'll just add new data.
    # If you want to clear data, uncomment the following lines:

    @account.teams.destroy_all
    @account.conversations.destroy_all
    @account.labels.destroy_all
    @account.inboxes.destroy_all
    @account.contacts.destroy_all

    puts 'Existing data preserved.'
  end

  def create_teams
    puts "Creating #{TOTAL_TEAMS} teams..."

    TOTAL_TEAMS.times do |i|
      team = @account.teams.create!(
        name: "#{Faker::Company.industry} Team #{i + 1}"
      )
      @teams << team
      puts "Created team: #{team.name}"
    end

    puts "Created #{@teams.size} teams."
  end

  def create_agents
    puts "Creating #{TOTAL_AGENTS} agents..."

    TOTAL_AGENTS.times do |i|
      # Create user with agent role
      random_suffix = SecureRandom.hex(4)
      user = User.create!(
        name: Faker::Name.name,
        email: "agent_#{i + 1}_#{random_suffix}@#{@account.domain || 'example.com'}",
        password: 'Password1!.',
        confirmed_at: Time.current
      )
      user.skip_confirmation!
      user.save!

      # Assign to account with agent role
      account_user = AccountUser.create!(
        account_id: @account.id,
        user_id: user.id,
        role: :agent
      )

      # Assign to random teams (1-3 teams per agent)
      teams_to_assign = @teams.sample(rand(1..3))
      teams_to_assign.each do |team|
        TeamMember.create!(
          team_id: team.id,
          user_id: user.id
        )
      end

      @agents << user
      puts "Created agent: #{user.name} (#{user.email})"
    end

    puts "Created #{@agents.size} agents."
  end

  def create_labels
    puts "Creating #{TOTAL_LABELS} labels..."

    TOTAL_LABELS.times do |i|
      label = @account.labels.create!(
        title: "Label-#{i + 1}-#{Faker::Lorem.word}",
        description: Faker::Company.catch_phrase,
        color: Faker::Color.hex_color
      )
      @labels << label
      puts "Created label: #{label.title}"
    end

    puts "Created #{@labels.size} labels."
  end

  def create_inboxes
    puts "Creating #{TOTAL_INBOXES} web inboxes..."

    TOTAL_INBOXES.times do |_i|
      # Create a website channel
      channel = Channel::WebWidget.create!(
        website_url: "https://#{Faker::Internet.domain_name}",
        account_id: @account.id
      )

      # Create inbox for the channel
      inbox = @account.inboxes.create!(
        name: "#{Faker::Company.name} Website",
        channel: channel
      )

      # Assign some agents to the inbox
      agents_to_assign = @agents.sample(rand(10..50))
      agents_to_assign.each do |agent|
        InboxMember.create!(inbox: inbox, user: agent)
      end

      @inboxes << inbox
      puts "Created inbox: #{inbox.name}"
    end

    puts "Created #{@inboxes.size} inboxes."
  end

  def create_contacts
    puts "Creating #{TOTAL_CONTACTS} contacts..."

    TOTAL_CONTACTS.times do |i|
      contact = @account.contacts.create!(
        name: Faker::Name.name,
        email: Faker::Internet.email,
        phone_number: Faker::PhoneNumber.cell_phone_in_e164,
        identifier: SecureRandom.uuid,
        additional_attributes: {
          company: Faker::Company.name,
          city: Faker::Address.city,
          country: Faker::Address.country,
          customer_since: Faker::Date.between(from: 2.years.ago, to: Date.today)
        }
      )
      @contacts << contact

      puts "Created #{i + 1} contacts so far..." if (i + 1) % 100 == 0
    end

    puts "Created #{@contacts.size} contacts."
  end

  def create_conversations
    puts "Creating #{TOTAL_CONVERSATIONS} conversations..."

    # Create a progress tracker
    progress_step = TOTAL_CONVERSATIONS / 10

    TOTAL_CONVERSATIONS.times do |i|
      # Select a random contact and inbox
      contact = @account.contacts.sample
      inbox = @account.inboxes.sample

      # Create a contact inbox if it doesn't exist
      contact_inbox = inbox.contact_inboxes.find_or_create_by!(
        contact: contact,
        source_id: SecureRandom.hex
      )

      # Select a random assignee (or nil for unassigned)
      assignee = rand(10) < 8 ? inbox.members.sample : nil

      # Select a random team (or nil for no team)
      team = rand(10) < 7 ? @teams.sample : nil

      # Select a random priority
      priority = @priorities.sample

      # Generate a random date within the past year
      created_at = Faker::Time.between(from: START_DATE, to: END_DATE)

      # Create the conversation following the account_seeder approach
      conversation = nil

      # Use ActiveRecord::Base.transaction to ensure data consistency
      ActiveRecord::Base.transaction do
        # Create the conversation
        conversation = contact_inbox.conversations.new(
          account: @account,
          inbox: inbox,
          contact: contact,
          assignee: assignee,
          team: team,
          priority: priority,
          created_at: created_at,
          updated_at: created_at
        )

        # Save the conversation - skip validations to avoid callbacks
        conversation.save(validate: false)

        # Add random labels (5-20 labels per conversation)
        labels_to_add = @labels.sample(rand(5..20))
        conversation.update_labels(labels_to_add.map(&:title))

        # Create messages for the conversation
        create_messages_for_conversation(conversation)
      end

      # Log progress
      if (i + 1) % progress_step == 0
        completion_percentage = ((i + 1).to_f / TOTAL_CONVERSATIONS * 100).round
        puts "#{completion_percentage}% complete: Created #{i + 1} conversations..."
      end
    end

    puts "Created #{TOTAL_CONVERSATIONS} conversations with messages and labels."
  end

  def create_messages_for_conversation(conversation)
    # Generate a sequence of messages with alternating sender types
    message_count = rand(MESSAGES_PER_CONVERSATION..MESSAGES_PER_CONVERSATION + 5)

    message_count.times do |i|
      # Determine if this is an incoming or outgoing message
      is_incoming = i.even? # Even indices are incoming, odd are outgoing

      created_at = conversation.created_at + i.hours

      if is_incoming
        # Create incoming message from contact
        conversation.messages.create!(
          account: @account,
          inbox: conversation.inbox,
          message_type: :incoming,
          content: Faker::Lorem.paragraph(sentence_count: rand(1..5)),
          sender: conversation.contact,
          created_at: created_at,
          updated_at: created_at
        )
      else
        # Create outgoing message from agent
        sender = conversation.assignee || @agents.sample
        conversation.messages.create!(
          account: @account,
          inbox: conversation.inbox,
          message_type: :outgoing,
          content: Faker::Lorem.paragraph(sentence_count: rand(1..5)),
          sender: sender,
          created_at: created_at,
          updated_at: created_at
        )
      end
    end

    # Update conversation timestamps to match the last message
    last_message_time = conversation.messages.maximum(:created_at)
    conversation.update_columns(
      last_activity_at: last_message_time,
      updated_at: last_message_time
    )
  end
end
# rubocop:enable all
