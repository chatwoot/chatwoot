# frozen_string_literal: true

# Reports Data Seeder
#
# Generates realistic test data for performance testing of reports and analytics.
# Creates conversations, messages, contacts, agents, teams, and labels with proper
# reporting events (first response times, resolution times, etc.) using time travel
# to generate historical data with realistic timestamps.
#
# Usage:
#   ACCOUNT_ID=1 ENABLE_ACCOUNT_SEEDING=true bundle exec rake db:seed:reports_data
#
# This will create:
#   - 1000 conversations with realistic message exchanges
#   - 100 contacts with realistic profiles
#   - 20 agents assigned to teams and inboxes
#   - 5 teams with realistic distribution
#   - 30 labels with random assignments
#   - 3 inboxes with agent assignments
#   - Realistic reporting events with historical timestamps
#
# Note: This seeder clears existing data for the account before seeding.

# rubocop:disable all
require 'faker'
require 'active_support/testing/time_helpers'

class Seeders::ReportsDataSeeder
  include ActiveSupport::Testing::TimeHelpers

  TOTAL_CONVERSATIONS = 1000
  TOTAL_CONTACTS = 100
  TOTAL_AGENTS = 20
  TOTAL_TEAMS = 5
  TOTAL_LABELS = 30
  TOTAL_INBOXES = 3
  MESSAGES_PER_CONVERSATION = 5
  START_DATE = 3.months.ago
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
    puts "Starting reports data seeding for account: #{@account.name}"

    # Clear existing data
    clear_existing_data

    create_teams
    create_agents
    create_labels
    create_inboxes
    create_contacts

    create_conversations

    puts "Completed reports data seeding for account: #{@account.name}"
  end

  private

  def clear_existing_data
    puts "Clearing existing data for account: #{@account.id}"
    @account.teams.destroy_all
    @account.conversations.destroy_all
    @account.labels.destroy_all
    @account.inboxes.destroy_all
    @account.contacts.destroy_all
  end

  def create_teams
    TOTAL_TEAMS.times do |i|
      team = @account.teams.create!(
        name: "#{Faker::Company.industry} Team #{i + 1}"
      )
      @teams << team
      print "\rCreating teams: #{i + 1}/#{TOTAL_TEAMS}"
    end

    print "\n"
  end

  def create_agents
    TOTAL_AGENTS.times do |i|
      random_suffix = SecureRandom.hex(4)
      user = User.create!(
        name: Faker::Name.name,
        email: "agent_#{i + 1}_#{random_suffix}@#{@account.domain || 'example.com'}",
        password: 'Password1!.',
        confirmed_at: Time.current
      )
      user.skip_confirmation!
      user.save!

      account_user = AccountUser.create!(
        account_id: @account.id,
        user_id: user.id,
        role: :agent
      )

      teams_to_assign = @teams.sample(rand(1..3))
      teams_to_assign.each do |team|
        TeamMember.create!(
          team_id: team.id,
          user_id: user.id
        )
      end

      @agents << user
      print "\rCreating agents: #{i + 1}/#{TOTAL_AGENTS}"
    end

    print "\n"
  end

  def create_labels
    TOTAL_LABELS.times do |i|
      label = @account.labels.create!(
        title: "Label-#{i + 1}-#{Faker::Lorem.word}",
        description: Faker::Company.catch_phrase,
        color: Faker::Color.hex_color
      )
      @labels << label
      print "\rCreating labels: #{i + 1}/#{TOTAL_LABELS}"
    end

    print "\n"
  end

  def create_inboxes
    TOTAL_INBOXES.times do |_i|
      channel = Channel::WebWidget.create!(
        website_url: "https://#{Faker::Internet.domain_name}",
        account_id: @account.id
      )

      inbox = @account.inboxes.create!(
        name: "#{Faker::Company.name} Website",
        channel: channel
      )

      # Assign agents to the inbox - ensure all agents are covered across inboxes
      if @inboxes.empty?
        # First inbox gets all agents to ensure coverage
        agents_to_assign = @agents
      else
        # Subsequent inboxes get random selection with some overlap
        min_agents = [@agents.size / TOTAL_INBOXES, 10].max
        max_agents = [(@agents.size * 0.8).to_i, 50].min
        agents_to_assign = @agents.sample(rand(min_agents..max_agents))
      end

      agents_to_assign.each do |agent|
        InboxMember.create!(inbox: inbox, user: agent)
      end

      @inboxes << inbox
      print "\rCreating inboxes: #{@inboxes.size}/#{TOTAL_INBOXES}"
    end

    print "\n"
  end

  def create_contacts
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

      print "\rCreating contacts: #{i + 1}/#{TOTAL_CONTACTS}"
    end

    print "\n"
  end

  def create_conversations
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

      # Use ActiveRecord::Base.transaction and travel_to for realistic timing
      ActiveRecord::Base.transaction do
        travel_to(created_at) do
          # Create the conversation
          conversation = contact_inbox.conversations.new(
            account: @account,
            inbox: inbox,
            contact: contact,
            assignee: assignee,
            team: team,
            priority: priority
          )

          # Save the conversation with callbacks to trigger events
          conversation.save!

          # Add random labels (5-20 labels per conversation)
          labels_to_add = @labels.sample(rand(5..20))
          conversation.update_labels(labels_to_add.map(&:title))

          # Create messages for the conversation with realistic timing
          create_messages_for_conversation(conversation)

          # Randomly resolve some conversations (70% chance)
          if rand < 0.7
            resolve_conversation(conversation)
          end
        end

        # Reset time for next conversation
        travel_back
      end

      # Show progress
      completion_percentage = ((i + 1).to_f / TOTAL_CONVERSATIONS * 100).round
      print "\rCreating conversations: #{i + 1}/#{TOTAL_CONVERSATIONS} (#{completion_percentage}%)"
    end

    print "\n"
  end

  def create_messages_for_conversation(conversation)
    # Generate a sequence of messages with alternating sender types
    message_count = rand(MESSAGES_PER_CONVERSATION..MESSAGES_PER_CONVERSATION + 5)
    first_agent_reply = true

    message_count.times do |i|
      # Determine if this is an incoming or outgoing message
      is_incoming = i.even? # Even indices are incoming, odd are outgoing

      # Add realistic delays between messages
      if i > 0
        delay = if is_incoming
          # Customer response time: 1 minute to 4 hours
          rand(1.minute..4.hours)
        else
          # Agent response time: 30 seconds to 2 hours (faster during business hours)
          if business_hours_active?(Time.current)
            rand(30.seconds..30.minutes)
          else
            rand(1.hour..8.hours)
          end
        end
        travel(delay)
      end

      if is_incoming
        # Create incoming message from contact
        message = conversation.messages.create!(
          account: @account,
          inbox: conversation.inbox,
          message_type: :incoming,
          content: Faker::Lorem.paragraph(sentence_count: rand(1..5)),
          sender: conversation.contact
        )
      else
        # Create outgoing message from agent
        sender = conversation.assignee || @agents.sample
        message = conversation.messages.create!(
          account: @account,
          inbox: conversation.inbox,
          message_type: :outgoing,
          content: Faker::Lorem.paragraph(sentence_count: rand(1..5)),
          sender: sender
        )

        # Trigger reporting events for agent replies
        if first_agent_reply
          trigger_first_reply_event(message)
          first_agent_reply = false
        else
          trigger_reply_event(message)
        end
      end
    end
  end

  def resolve_conversation(conversation)
    # Add some time before resolving (30 minutes to 24 hours after last message)
    resolution_delay = rand(30.minutes..24.hours)
    travel(resolution_delay)
    conversation.update!(status: :resolved)

    # Trigger conversation resolved reporting event
    trigger_conversation_resolved_event(conversation)
  end

  def business_hours_active?(time)
    # Simple business hours check: Monday-Friday, 9 AM - 6 PM
    weekday = time.wday
    hour = time.hour
    weekday.between?(1, 5) && hour.between?(9, 17)
  end

  def trigger_first_reply_event(message)
    event_data = {
      message: message,
      conversation: message.conversation
    }

    ReportingEventListener.instance.first_reply_created(
      Events::Base.new('first_reply_created', Time.current, event_data)
    )
  end

  def trigger_reply_event(message)
    # Calculate waiting_since as the time of the last customer message
    last_customer_message = message.conversation.messages
                                  .where(message_type: :incoming)
                                  .where('created_at < ?', message.created_at)
                                  .order(:created_at)
                                  .last

    waiting_since = last_customer_message&.created_at || message.conversation.created_at

    event_data = {
      message: message,
      conversation: message.conversation,
      waiting_since: waiting_since
    }

    ReportingEventListener.instance.reply_created(
      Events::Base.new('reply_created', Time.current, event_data)
    )
  end

  def trigger_conversation_resolved_event(conversation)
    event_data = {
      conversation: conversation
    }

    ReportingEventListener.instance.conversation_resolved(
      Events::Base.new('conversation_resolved', Time.current, event_data)
    )
  end
end
# rubocop:enable all
