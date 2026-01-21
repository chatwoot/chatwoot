# frozen_string_literal: true

# Reports Data Seeder
#
# Generates realistic test data for performance testing of reports and analytics.
# Creates conversations, messages, contacts, agents, teams, and labels with proper
# reporting events (first response times, resolution times, etc.) using time travel
# to generate historical data with realistic timestamps.
#
# Usage:
#   ENABLE_ACCOUNT_SEEDING=true bundle exec rake db:seed:reports_data
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

require 'faker'
require_relative 'conversation_creator'
require_relative 'message_creator'

# rubocop:disable Rails/Output, Metrics/ClassLength
class Seeders::Reports::ReportDataSeeder
  include ActiveSupport::Testing::TimeHelpers

  TOTAL_INBOXES = 3

  def initialize(account:, config: {})
    raise 'Account Seeding is not allowed.' unless ENV.fetch('ENABLE_ACCOUNT_SEEDING', !Rails.env.production?)

    @account = account
    initialize_config(config)
    @teams = []
    @agents = []
    @labels = []
    @inboxes = []
    @contacts = []
    @captain_assistant = nil
  end

  def initialize_config(config)
    defaults = { total_conversations: 1000, total_contacts: 100, total_agents: 20,
                 total_teams: 5, total_labels: 30, days_range: 90 }
    config = defaults.merge(config)

    @total_conversations = config[:total_conversations]
    @total_contacts = config[:total_contacts]
    @total_agents = config[:total_agents]
    @total_teams = config[:total_teams]
    @total_labels = config[:total_labels]
    @days_range = config[:days_range]
  end

  def perform!
    puts "Starting reports data seeding for account: #{@account.name}"

    # Clear existing data
    clear_existing_data

    create_captain_assistant
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
    @account.agents.destroy_all
    @account.reporting_events.destroy_all
    Captain::Assistant.where(account: @account).destroy_all if defined?(Captain::Assistant)
  end

  def create_captain_assistant
    return unless defined?(Captain::Assistant)

    @captain_assistant = Captain::Assistant.create!(
      account: @account,
      name: 'Support Bot',
      description: 'AI assistant for customer support'
    )
    puts 'Created Captain assistant: Support Bot'
  end

  def create_teams
    @total_teams.times do |i|
      team = @account.teams.create!(
        name: "#{Faker::Company.industry} Team #{i + 1}"
      )
      @teams << team
      print "\rCreating teams: #{i + 1}/#{@total_teams}"
    end

    print "\n"
  end

  def create_agents
    @total_agents.times do |i|
      user = create_single_agent(i)
      assign_agent_to_teams(user)
      @agents << user
      print "\rCreating agents: #{i + 1}/#{@total_agents}"
    end

    print "\n"
  end

  def create_single_agent(index)
    random_suffix = SecureRandom.hex(4)
    user = User.create!(
      name: Faker::Name.name,
      email: "agent_#{index + 1}_#{random_suffix}@#{@account.domain || 'example.com'}",
      password: 'Password1!.',
      confirmed_at: Time.current
    )
    user.skip_confirmation!
    user.save!

    AccountUser.create!(
      account_id: @account.id,
      user_id: user.id,
      role: :agent
    )

    user
  end

  def assign_agent_to_teams(user)
    teams_to_assign = @teams.sample(rand(1..3))
    teams_to_assign.each do |team|
      TeamMember.create!(
        team_id: team.id,
        user_id: user.id
      )
    end
  end

  def create_labels
    @total_labels.times do |i|
      label = @account.labels.create!(
        title: "Label-#{i + 1}-#{Faker::Lorem.word}",
        description: Faker::Company.catch_phrase,
        color: Faker::Color.hex_color
      )
      @labels << label
      print "\rCreating labels: #{i + 1}/#{@total_labels}"
    end

    print "\n"
  end

  def create_inboxes
    # Create inboxes: 2/3 with Captain (bot inboxes) and 1/3 without (human-only)
    bot_inbox_count = (TOTAL_INBOXES * 2 / 3.0).ceil
    human_inbox_count = TOTAL_INBOXES - bot_inbox_count

    bot_inbox_count.times do |i|
      inbox = create_web_inbox_with_captain("Support Bot Inbox #{i + 1}")
      assign_agents_to_inbox(inbox)
      @inboxes << inbox
      print "\rCreating inboxes: #{@inboxes.size}/#{TOTAL_INBOXES}"
    end

    human_inbox_count.times do |i|
      inbox = create_web_inbox("Human Support Inbox #{i + 1}")
      assign_agents_to_inbox(inbox)
      @inboxes << inbox
      print "\rCreating inboxes: #{@inboxes.size}/#{TOTAL_INBOXES}"
    end

    print "\n"
  end

  def create_web_inbox_with_captain(name)
    inbox = create_web_inbox(name)

    if @captain_assistant && defined?(CaptainInbox)
      CaptainInbox.create!(
        captain_assistant: @captain_assistant,
        inbox: inbox
      )
    end

    inbox
  end

  def create_web_inbox(name)
    channel = Channel::WebWidget.create!(
      website_url: "https://#{Faker::Internet.domain_name}",
      account_id: @account.id
    )

    @account.inboxes.create!(
      name: name,
      channel: channel
    )
  end

  def assign_agents_to_inbox(inbox)
    agents_to_assign = if @inboxes.empty?
                         # First inbox gets all agents to ensure coverage
                         @agents
                       else
                         # Subsequent inboxes get random selection with some overlap
                         min_agents = [(@agents.size / TOTAL_INBOXES), 1].max
                         max_agents = [(@agents.size * 0.8).to_i, @agents.size].min
                         sample_count = rand([min_agents, max_agents].min..[min_agents, max_agents].max)
                         @agents.sample(sample_count)
                       end

    agents_to_assign.each do |agent|
      InboxMember.create!(inbox: inbox, user: agent)
    end
  end

  def create_contacts
    @total_contacts.times do |i|
      contact = @account.contacts.create!(
        name: Faker::Name.name,
        email: Faker::Internet.email,
        phone_number: Faker::PhoneNumber.cell_phone_in_e164,
        identifier: SecureRandom.uuid,
        additional_attributes: {
          company: Faker::Company.name,
          city: Faker::Address.city,
          country: Faker::Address.country,
          customer_since: Faker::Date.between(from: 2.years.ago, to: Time.zone.today)
        }
      )
      @contacts << contact

      print "\rCreating contacts: #{i + 1}/#{@total_contacts}"
    end

    print "\n"
  end

  def create_conversations
    conversation_creator = Seeders::Reports::ConversationCreator.new(
      account: @account,
      resources: {
        contacts: @contacts,
        inboxes: @inboxes,
        teams: @teams,
        labels: @labels,
        agents: @agents,
        captain_assistant: @captain_assistant
      }
    )

    @total_conversations.times do |i|
      created_at = Faker::Time.between(from: @days_range.days.ago, to: Time.current)
      conversation_creator.create_conversation(created_at: created_at)

      completion_percentage = ((i + 1).to_f / @total_conversations * 100).round
      print "\rCreating conversations: #{i + 1}/#{@total_conversations} (#{completion_percentage}%)"
    end

    print "\n"
  end
end
# rubocop:enable Rails/Output, Metrics/ClassLength
