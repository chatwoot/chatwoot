# frozen_string_literal: true

require 'faker'
require 'active_support/testing/time_helpers'

class Seeders::Reports::ConversationCreator
  include ActiveSupport::Testing::TimeHelpers

  def initialize(account:, resources:)
    @account = account
    @contacts = resources[:contacts]
    @inboxes = resources[:inboxes]
    @teams = resources[:teams]
    @labels = resources[:labels]
    @agents = resources[:agents]
    @captain_assistant = resources[:captain_assistant]
    @priorities = [nil, 'urgent', 'high', 'medium', 'low']
  end

  # rubocop:disable Metrics/MethodLength
  def create_conversation(created_at:)
    conversation = nil
    should_resolve = false
    resolution_time = nil

    ActiveRecord::Base.transaction do
      travel_to(created_at) do
        conversation = build_conversation
        conversation.save!

        add_labels_to_conversation(conversation)

        # Check if this is a bot inbox or human-only inbox
        if inbox_has_captain?(conversation.inbox)
          create_bot_conversation_flow(conversation, created_at)
        else
          create_human_conversation_flow(conversation)
        end

        # Determine if should resolve but don't update yet
        should_resolve = rand > 0.3
        if should_resolve
          resolution_delay = rand((30.minutes)..(24.hours))
          resolution_time = created_at + resolution_delay
        end
      end

      travel_back
    end

    # Now resolve outside of time travel if needed
    if should_resolve && resolution_time
      # rubocop:disable Rails/SkipsModelValidations
      conversation.update_column(:status, :resolved)
      conversation.update_column(:updated_at, resolution_time)
      # rubocop:enable Rails/SkipsModelValidations

      # Trigger the event with proper timestamp
      travel_to(resolution_time) do
        trigger_conversation_resolved_event(conversation)
      end
      travel_back
    end

    conversation
  end
  # rubocop:enable Metrics/MethodLength

  private

  def build_conversation
    contact = @contacts.sample
    inbox = @inboxes.sample

    contact_inbox = find_or_create_contact_inbox(contact, inbox)
    assignee = select_assignee(inbox)
    team = select_team
    priority = @priorities.sample

    contact_inbox.conversations.new(
      account: @account,
      inbox: inbox,
      contact: contact,
      assignee: assignee,
      team: team,
      priority: priority
    )
  end

  def find_or_create_contact_inbox(contact, inbox)
    inbox.contact_inboxes.find_or_create_by!(
      contact: contact,
      source_id: SecureRandom.hex
    )
  end

  def select_assignee(inbox)
    rand(10) < 8 ? inbox.members.sample : nil
  end

  def select_team
    rand(10) < 7 ? @teams.sample : nil
  end

  def add_labels_to_conversation(conversation)
    labels_to_add = @labels.sample(rand(5..20))
    conversation.update_labels(labels_to_add.map(&:title))
  end

  def create_messages_for_conversation(conversation, include_bot: false)
    message_creator = Seeders::Reports::MessageCreator.new(
      account: @account,
      agents: @agents,
      conversation: conversation,
      captain_assistant: include_bot ? @captain_assistant : nil
    )
    message_creator.create_messages
  end

  def inbox_has_captain?(inbox)
    return false unless @captain_assistant && inbox.respond_to?(:captain_assistant)

    inbox.captain_assistant.present?
  end

  def create_bot_conversation_flow(conversation, _created_at)
    message_creator = Seeders::Reports::MessageCreator.new(
      account: @account,
      agents: @agents,
      conversation: conversation,
      captain_assistant: @captain_assistant
    )

    # Create initial customer message
    message_creator.create_incoming_message

    # Add delay for bot response
    travel(rand((5.seconds)..(30.seconds)))

    # Create bot response
    message_creator.create_bot_message

    # Randomly decide outcome: 30% bot resolves, 50% handoff to human, 20% abandoned
    outcome = rand(100)

    if outcome < 30
      # Bot resolves - no more messages needed, will be resolved later
      nil
    elsif outcome < 80
      # Bot hands off to human - use travel to move forward from current time
      travel(rand((1.minute)..(10.minutes)))
      trigger_bot_handoff_event(conversation)
      # Continue with human agent messages
      create_human_messages_after_handoff(message_creator)
    end
    # else: 20% abandoned - no further action
  end

  def create_human_conversation_flow(conversation)
    create_messages_for_conversation(conversation)
  end

  def create_human_messages_after_handoff(message_creator)
    # Create a few more human agent messages after handoff
    message_count = rand(2..4)
    message_count.times do |i|
      travel(rand((1.minute)..(30.minutes)))
      if i.even?
        message_creator.create_incoming_message
      else
        message_creator.create_human_outgoing_message
      end
    end
  end

  def trigger_bot_handoff_event(conversation)
    event_data = { conversation: conversation }

    ReportingEventListener.instance.conversation_bot_handoff(
      Events::Base.new('conversation_bot_handoff', Time.current, event_data)
    )
  end

  def trigger_conversation_resolved_event(conversation)
    event_data = { conversation: conversation }

    ReportingEventListener.instance.conversation_resolved(
      Events::Base.new('conversation_resolved', Time.current, event_data)
    )
  end
end
