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

require 'faker'
require_relative 'conversation_creator'
require_relative 'message_creator'

# rubocop:disable Rails/Output
class Seeders::Reports::ReportDataSeeder
  include ActiveSupport::Testing::TimeHelpers

  TOTAL_CONVERSATIONS = 1000
  TOTAL_CONTACTS = 100
  TOTAL_AGENTS = 20
  TOTAL_TEAMS = 5
  TOTAL_LABELS = 30
  TOTAL_INBOXES = 3
  MESSAGES_PER_CONVERSATION = 5
  START_DATE = 3.months.ago # rubocop:disable Rails/RelativeDateConstant
  END_DATE = Time.current

  def initialize(account:)
    raise 'Account Seeding is not allowed.' unless ENV.fetch('ENABLE_ACCOUNT_SEEDING', !Rails.env.production?)

    @account = account
    @teams = []
    @agents = []
    @labels = []
    @inboxes = []
    @contacts = []
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
    @account.agents.destroy_all
    @account.reporting_events.destroy_all
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
      user = create_single_agent(i)
      assign_agent_to_teams(user)
      @agents << user
      print "\rCreating agents: #{i + 1}/#{TOTAL_AGENTS}"
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
      inbox = create_single_inbox
      assign_agents_to_inbox(inbox)
      @inboxes << inbox
      print "\rCreating inboxes: #{@inboxes.size}/#{TOTAL_INBOXES}"
    end

    print "\n"
  end

  def create_single_inbox
    channel = Channel::WebWidget.create!(
      website_url: "https://#{Faker::Internet.domain_name}",
      account_id: @account.id
    )

    @account.inboxes.create!(
      name: "#{Faker::Company.name} Website",
      channel: channel
    )
  end

  def assign_agents_to_inbox(inbox)
    agents_to_assign = if @inboxes.empty?
                         # First inbox gets all agents to ensure coverage
                         @agents
                       else
                         # Subsequent inboxes get random selection with some overlap
                         min_agents = [@agents.size / TOTAL_INBOXES, 10].max
                         max_agents = [(@agents.size * 0.8).to_i, 50].min
                         @agents.sample(rand(min_agents..max_agents))
                       end

    agents_to_assign.each do |agent|
      InboxMember.create!(inbox: inbox, user: agent)
    end
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
          customer_since: Faker::Date.between(from: 2.years.ago, to: Time.zone.today)
        }
      )
      @contacts << contact

      print "\rCreating contacts: #{i + 1}/#{TOTAL_CONTACTS}"
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
        agents: @agents
      }
    )

    TOTAL_CONVERSATIONS.times do |i|
      created_at = Faker::Time.between(from: START_DATE, to: END_DATE)
      conversation_creator.create_conversation(created_at: created_at)

      completion_percentage = ((i + 1).to_f / TOTAL_CONVERSATIONS * 100).round
      print "\rCreating conversations: #{i + 1}/#{TOTAL_CONVERSATIONS} (#{completion_percentage}%)"
    end

    print "\n"
  end
end
# rubocop:enable Rails/Output
