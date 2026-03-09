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
    @priorities = [nil, 'urgent', 'high', 'medium', 'low']
  end

  def create_conversation(created_at:)
    conversation = nil

    ActiveRecord::Base.transaction do
      travel_to(created_at) do
        conversation = build_conversation
        conversation.save!

        add_labels_to_conversation(conversation)
        create_messages_for_conversation(conversation)
        resolve_conversation_if_needed(conversation)
      end

      travel_back
    end

    conversation
  end

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

  def create_messages_for_conversation(conversation)
    message_creator = Seeders::Reports::MessageCreator.new(
      account: @account,
      agents: @agents,
      conversation: conversation
    )
    message_creator.create_messages
  end

  def resolve_conversation_if_needed(conversation)
    return unless rand < 0.7

    resolution_delay = rand((30.minutes)..(24.hours))
    travel(resolution_delay)
    conversation.update!(status: :resolved)

    trigger_conversation_resolved_event(conversation)
  end

  def trigger_conversation_resolved_event(conversation)
    event_data = { conversation: conversation }

    ReportingEventListener.instance.conversation_resolved(
      Events::Base.new('conversation_resolved', Time.current, event_data)
    )
  end
end
