# frozen_string_literal: true

require 'faker'
require 'active_support/testing/time_helpers'

# Seeds Captain assistant activity for the reports/overview test data.
#
# Produces a variety of assistant-handled conversations in a single web inbox so
# every Captain assistant overview metric (handled, auto-resolution, handoff,
# hours saved, reopen rate, conversation depth) has realistic data:
#   - :resolved_by_assistant  assistant answers and Captain auto-resolves
#   - :handled_by_both        assistant answers, a human also replies and resolves
#   - :handed_off             assistant answers, then hands off to a human
#   - :resolved_and_reopened  Captain resolves, then the conversation reopens
#
# Reporting events are fired through ReportingEventListener directly (mirroring
# ConversationCreator), and outcome facts are folded through
# Captain::ConversationOutcomeTracker at the same frozen timestamps, so both the
# event-backed and outcome-backed overview metrics get populated the same way
# production would populate them.
class Seeders::Reports::AssistantConversationCreator # rubocop:disable Metrics/ClassLength
  include ActiveSupport::Testing::TimeHelpers

  OUTCOMES = %i[resolved_by_assistant handled_by_both handed_off resolved_and_reopened].freeze
  HANDOFF_REASON_CATEGORIES = %w[
    customer_request missing_knowledge unsupported_request policy_restriction tool_failure pending_clarification
  ].freeze
  # Rating distribution skews positive, mirroring typical CSAT response shapes.
  CSAT_RATINGS = [5, 5, 5, 4, 4, 3, 2].freeze
  CSAT_RESPONSE_CHANCE = 0.45

  def initialize(account:, assistant:, inbox:, resources:)
    @account = account
    @assistant = assistant
    @inbox = inbox
    @contacts = resources[:contacts]
    @agents = inbox.members.to_a.presence || resources[:agents]
  end

  def create_conversation(created_at:, outcome:)
    conversation = nil

    travel_to(created_at) do
      conversation = build_conversation
      conversation.save!
      seed_dialogue(conversation, outcome)
    end
    travel_back

    apply_outcome(conversation, created_at, outcome)
    conversation
  end

  private

  def build_conversation
    contact = @contacts.sample
    contact_inbox = @inbox.contact_inboxes.find_or_create_by!(contact: contact, source_id: SecureRandom.hex)

    contact_inbox.conversations.create!(
      account: @account,
      inbox: @inbox,
      contact: contact,
      priority: [nil, 'high', 'medium', 'low'].sample
    )
  end

  # Builds the message exchange for the conversation while time is frozen at its
  # creation moment. Every outcome starts with a customer question and at least
  # one public assistant reply so the conversation lands in the assistant's
  # handled set; some outcomes add a human reply or a handoff.
  def seed_dialogue(conversation, outcome)
    customer_message = incoming_message(conversation)
    tracker(conversation).record_eligibility

    travel(rand((20.seconds)..(5.minutes)))
    assistant_reply(conversation, waiting_since: customer_message.created_at)

    case outcome
    when :handed_off then seed_handoff(conversation)
    when :handled_by_both then seed_human_turn(conversation)
    else seed_assistant_follow_up(conversation)
    end
  end

  def seed_handoff(conversation)
    travel(rand((1.minute)..(10.minutes)))
    handoff_to_human(conversation)
    travel(rand((1.minute)..(15.minutes)))
    human_reply(conversation)
  end

  def seed_human_turn(conversation)
    travel(rand((1.minute)..(15.minutes)))
    human_reply(conversation)
  end

  # Pure assistant threads occasionally take a second turn, giving depth > 1.
  def seed_assistant_follow_up(conversation)
    return unless rand < 0.6

    travel(rand((1.minute)..(10.minutes)))
    follow_up = incoming_message(conversation)
    travel(rand((20.seconds)..(5.minutes)))
    assistant_reply(conversation, waiting_since: follow_up.created_at)
  end

  def apply_outcome(conversation, created_at, outcome)
    resolved_at = created_at + rand((30.minutes)..(8.hours))

    case outcome
    when :resolved_by_assistant
      resolve_by_captain(conversation, resolved_at)
    when :handled_by_both
      resolve_by_human(conversation, resolved_at)
    when :handed_off
      resolve_by_human(conversation, resolved_at) if rand < 0.6
    when :resolved_and_reopened
      resolve_by_captain(conversation, resolved_at)
      reopen(conversation, resolved_at + rand((1.hour)..(24.hours)))
    end
  end

  def incoming_message(conversation)
    conversation.messages.create!(
      account: @account,
      inbox: @inbox,
      message_type: :incoming,
      content: Faker::Lorem.paragraph(sentence_count: rand(1..3)),
      sender: conversation.contact
    )
  end

  def assistant_reply(conversation, waiting_since:)
    message = conversation.messages.create!(
      account: @account,
      inbox: @inbox,
      message_type: :outgoing,
      private: false,
      content: Faker::Lorem.paragraph(sentence_count: rand(1..4)),
      sender: @assistant
    )
    trigger_reply_time(message, waiting_since)
    tracker(conversation).record_captain_reply(message: message)
    message
  end

  def human_reply(conversation)
    agent = @agents.sample
    conversation.update_column(:assignee_id, agent.id) if conversation.assignee_id.nil? # rubocop:disable Rails/SkipsModelValidations

    message = conversation.messages.create!(
      account: @account,
      inbox: @inbox,
      message_type: :outgoing,
      private: false,
      content: Faker::Lorem.paragraph(sentence_count: rand(1..4)),
      sender: agent
    )
    tracker(conversation).record_human_reply(message: message)
    message
  end

  def resolve_by_captain(conversation, resolved_at)
    mark_resolved(conversation, resolved_at)
    travel_to(resolved_at) do
      trigger_event('conversation_resolved', conversation)
      trigger_captain_event(Events::Types::CAPTAIN_CONVERSATION_RESOLVED, conversation)
      tracker(conversation).record_resolution(at: Time.current)
    end
    travel_back
    seed_csat_response(conversation, resolved_at) if rand < CSAT_RESPONSE_CHANCE
  end

  def resolve_by_human(conversation, resolved_at)
    mark_resolved(conversation, resolved_at)
    travel_to(resolved_at) do
      trigger_event('conversation_resolved', conversation)
      tracker(conversation).record_resolution(at: Time.current)
    end
    travel_back
    seed_csat_response(conversation, resolved_at) if rand < CSAT_RESPONSE_CHANCE
  end

  def reopen(conversation, reopened_at)
    # rubocop:disable Rails/SkipsModelValidations
    conversation.update_column(:status, :open)
    conversation.update_column(:updated_at, reopened_at)
    # rubocop:enable Rails/SkipsModelValidations

    travel_to(reopened_at) do
      trigger_event('conversation_opened', conversation)
      tracker(conversation).record_reopen(at: Time.current)
    end
    travel_back
  end

  def handoff_to_human(conversation)
    trigger_captain_event(Events::Types::CAPTAIN_CONVERSATION_HANDED_OFF, conversation)
    tracker(conversation).record_handoff(at: Time.current, reason_category: HANDOFF_REASON_CATEGORIES.sample)
  end

  # A share of resolved conversations gets a CSAT response so the experience
  # metrics have data. The survey message carries no sender so the reply
  # folding never mistakes it for a Captain or human reply.
  def seed_csat_response(conversation, resolved_at)
    travel_to(resolved_at + rand((5.minutes)..(2.hours))) do
      message = conversation.messages.create!(
        account: @account,
        inbox: @inbox,
        message_type: :outgoing,
        content_type: :input_csat,
        content: 'Please rate this conversation',
        private: false
      )
      response = CsatSurveyResponse.create!(
        account: @account,
        conversation: conversation,
        contact: conversation.contact,
        message: message,
        rating: CSAT_RATINGS.sample
      )
      tracker(conversation).record_csat(response: response)
    end
    travel_back
  end

  def tracker(conversation)
    Captain::ConversationOutcomeTracker.new(conversation: conversation, assistant: @assistant)
  end

  def mark_resolved(conversation, resolved_at)
    # rubocop:disable Rails/SkipsModelValidations
    conversation.update_column(:status, :resolved)
    conversation.update_column(:updated_at, resolved_at)
    # rubocop:enable Rails/SkipsModelValidations
  end

  def trigger_event(name, conversation)
    ReportingEventListener.instance.public_send(
      name, Events::Base.new(name, Time.current, { conversation: conversation })
    )
  end

  def trigger_captain_event(name, conversation)
    event = Events::Base.new(name, Time.current, { conversation: conversation, source: 'inference' })
    Captain::ReportingEventListener.instance.public_send(event.method_name, event)
  end

  def trigger_reply_time(message, waiting_since)
    ReportingEventListener.instance.reply_created(
      Events::Base.new('reply_created', Time.current,
                       { message: message, conversation: message.conversation, waiting_since: waiting_since })
    )
  end
end
