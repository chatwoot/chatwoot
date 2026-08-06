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
#   - 1 Captain assistant bound to a single web inbox, with knowledge (FAQs + documents)
#     and a variety of assistant-handled conversations (auto-resolved, handed off,
#     handled with a human, resolved-then-reopened) for the assistant overview page
#   - Realistic reporting events with historical timestamps
#
# Note: This seeder clears existing data for the account before seeding.

require 'faker'
require_relative 'conversation_creator'
require_relative 'message_creator'
require_relative 'assistant_conversation_creator'

# rubocop:disable Rails/Output, Metrics/ClassLength
class Seeders::Reports::ReportDataSeeder
  include ActiveSupport::Testing::TimeHelpers

  TOTAL_CONVERSATIONS = 1000
  TOTAL_CONTACTS = 100
  TOTAL_AGENTS = 20
  TOTAL_TEAMS = 5
  TOTAL_LABELS = 30
  TOTAL_INBOXES = 3
  MESSAGES_PER_CONVERSATION = 5
  # Captain assistant conversations, split across the outcomes the overview page reports on.
  TOTAL_ASSISTANT_CONVERSATIONS = 120
  ASSISTANT_KNOWLEDGE_APPROVED = 14
  ASSISTANT_KNOWLEDGE_PENDING = 6
  ASSISTANT_DOCUMENTS = 4
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
    @assistant = nil
    @assistant_inbox = nil
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
    create_assistant

    create_conversations
    create_assistant_conversations

    puts "Completed reports data seeding for account: #{@account.name}"
  end

  private

  def clear_existing_data
    puts "Clearing existing data for account: #{@account.id}"
    clear_assistant_data
    @account.teams.destroy_all
    @account.conversations.destroy_all
    @account.labels.destroy_all
    @account.inboxes.destroy_all
    @account.contacts.destroy_all
    @account.agents.destroy_all
    @account.reporting_events.destroy_all
  end

  # Delete Captain records directly (assistant associations are destroy_async, which
  # would leave rows around mid-reseed); order respects foreign keys.
  def clear_assistant_data
    assistant_ids = Captain::Assistant.for_account(@account.id).select(:id)
    Captain::AssistantResponse.by_account(@account.id).delete_all
    Captain::Document.for_account(@account.id).delete_all
    CaptainInbox.where(captain_assistant_id: assistant_ids).delete_all
    Captain::Assistant.for_account(@account.id).delete_all
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

  # One assistant, bound to a single web inbox (the first one), as the overview page expects.
  def create_assistant
    @account.enable_features!('captain_integration', 'captain_integration_v2')
    @assistant_inbox = @inboxes.first
    @assistant = Captain::Assistant.create!(
      account: @account,
      name: "#{Faker::Company.name} Copilot",
      description: 'Captain assistant handling website support conversations.',
      config: { feature_faq: true, feature_memory: true, product_name: @account.name }
    )
    CaptainInbox.create!(captain_assistant: @assistant, inbox: @assistant_inbox)
    create_assistant_knowledge

    puts "Created assistant '#{@assistant.name}' for inbox '#{@assistant_inbox.name}'"
  end

  def create_assistant_knowledge
    ASSISTANT_KNOWLEDGE_APPROVED.times { create_assistant_response(:approved) }
    ASSISTANT_KNOWLEDGE_PENDING.times { create_assistant_response(:pending) }

    ASSISTANT_DOCUMENTS.times do
      Captain::Document.create!(
        account: @account,
        assistant: @assistant,
        name: Faker::Company.catch_phrase,
        external_link: "https://#{Faker::Internet.domain_name}/#{Faker::Internet.slug}",
        content: Faker::Lorem.paragraphs(number: rand(2..4)).join("\n\n"),
        status: :available,
        sync_status: :synced
      )
    end
  end

  def create_assistant_response(status)
    Captain::AssistantResponse.create!(
      account: @account,
      assistant: @assistant,
      question: "#{Faker::Lorem.sentence(word_count: rand(4..8)).chomp('.')}?",
      answer: Faker::Lorem.paragraph(sentence_count: rand(2..4)),
      status: status
    )
  end

  def create_assistant_conversations
    creator = Seeders::Reports::AssistantConversationCreator.new(
      account: @account,
      assistant: @assistant,
      inbox: @assistant_inbox,
      resources: { contacts: @contacts, agents: @agents }
    )

    outcomes = assistant_outcome_distribution
    outcomes.each_with_index do |outcome, i|
      created_at = Faker::Time.between(from: 65.days.ago, to: END_DATE)
      creator.create_conversation(created_at: created_at, outcome: outcome)

      print "\rCreating assistant conversations: #{i + 1}/#{outcomes.size}"
    end

    print "\n"
  end

  # Weighted mix of outcomes so every overview metric has meaningful numbers, shuffled
  # so they interleave across the time span rather than clustering by type.
  def assistant_outcome_distribution
    counts = {
      resolved_by_assistant: (TOTAL_ASSISTANT_CONVERSATIONS * 0.4).round,
      handled_by_both: (TOTAL_ASSISTANT_CONVERSATIONS * 0.25).round,
      handed_off: (TOTAL_ASSISTANT_CONVERSATIONS * 0.2).round,
      resolved_and_reopened: (TOTAL_ASSISTANT_CONVERSATIONS * 0.15).round
    }
    counts.flat_map { |outcome, count| [outcome] * count }.shuffle
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
# rubocop:enable Rails/Output, Metrics/ClassLength
