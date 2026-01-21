# frozen_string_literal: true

require 'faker'
require 'active_support/testing/time_helpers'

class Seeders::Reports::MessageCreator
  include ActiveSupport::Testing::TimeHelpers

  MESSAGES_PER_CONVERSATION = 5

  def initialize(account:, agents:, conversation:, captain_assistant: nil)
    @account = account
    @agents = agents
    @conversation = conversation
    @captain_assistant = captain_assistant
  end

  def create_messages
    message_count = rand(MESSAGES_PER_CONVERSATION..MESSAGES_PER_CONVERSATION + 5)
    first_agent_reply = true

    message_count.times do |i|
      message = create_single_message(i)
      first_agent_reply = handle_reply_tracking(message, i, first_agent_reply)
    end
  end

  def create_single_message(index)
    is_incoming = index.even?
    add_realistic_delay(index, is_incoming) if index.positive?
    create_message(is_incoming)
  end

  def handle_reply_tracking(message, index, first_agent_reply)
    return first_agent_reply if index.even? # Skip incoming messages

    handle_agent_reply_events(message, first_agent_reply)
    false # No longer first reply after any agent message
  end

  def create_incoming_message
    @conversation.messages.create!(
      account: @account,
      inbox: @conversation.inbox,
      message_type: :incoming,
      content: generate_customer_message_content,
      sender: @conversation.contact
    )
  end

  def create_bot_message
    return unless @captain_assistant

    @conversation.messages.create!(
      account: @account,
      inbox: @conversation.inbox,
      message_type: :outgoing,
      content: generate_bot_response_content,
      sender: @captain_assistant
    )
  end

  def create_human_outgoing_message
    sender = @conversation.assignee || @agents.sample

    message = @conversation.messages.create!(
      account: @account,
      inbox: @conversation.inbox,
      message_type: :outgoing,
      content: generate_message_content,
      sender: sender
    )

    # Trigger reply events for human messages after handoff
    trigger_reply_event(message)
    message
  end

  private

  def add_realistic_delay(_message_index, is_incoming)
    delay = calculate_message_delay(is_incoming)
    travel(delay)
  end

  def calculate_message_delay(is_incoming)
    if is_incoming
      # Customer response time: 1 minute to 4 hours
      rand((1.minute)..(4.hours))
    elsif business_hours_active?(Time.current)
      # Agent response time varies by business hours
      rand((30.seconds)..(30.minutes))
    else
      rand((1.hour)..(8.hours))
    end
  end

  def create_message(is_incoming)
    if is_incoming
      create_incoming_message
    else
      create_outgoing_message
    end
  end

  def create_outgoing_message
    sender = @conversation.assignee || @agents.sample

    @conversation.messages.create!(
      account: @account,
      inbox: @conversation.inbox,
      message_type: :outgoing,
      content: generate_message_content,
      sender: sender
    )
  end

  def generate_message_content
    Faker::Lorem.paragraph(sentence_count: rand(1..5))
  end

  def generate_customer_message_content
    customer_messages = [
      'Hi, I need help with my order.',
      'Can you assist me with a billing issue?',
      'I have a question about my account.',
      "I'm having trouble logging in.",
      'How do I change my password?',
      'When will my order arrive?',
      "I'd like to request a refund.",
      'Can you help me update my shipping address?',
      'I received the wrong item.',
      'Is there a way to track my package?',
      Faker::Lorem.paragraph(sentence_count: rand(1..3))
    ]
    customer_messages.sample
  end

  def generate_bot_response_content
    bot_responses = [
      "Hello! I'm here to help. Let me look into that for you.",
      'Thank you for reaching out. I can assist you with this.',
      'I understand your concern. Let me check our records.',
      'Sure, I can help with that! Could you provide more details?',
      "I've found some information that might help.",
      'Let me connect you with a specialist who can better assist you.',
      'Based on your question, here are some options available to you.',
      'I can see your account details. Let me review this for you.',
      "Thank you for your patience. I'm processing your request now.",
      'Is there anything else I can help you with today?'
    ]
    bot_responses.sample
  end

  def handle_agent_reply_events(message, is_first_reply)
    if is_first_reply
      trigger_first_reply_event(message)
    else
      trigger_reply_event(message)
    end
  end

  def business_hours_active?(time)
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
    waiting_since = calculate_waiting_since(message)

    event_data = {
      message: message,
      conversation: message.conversation,
      waiting_since: waiting_since
    }

    ReportingEventListener.instance.reply_created(
      Events::Base.new('reply_created', Time.current, event_data)
    )
  end

  def calculate_waiting_since(message)
    last_customer_message = message.conversation.messages
                                   .where(message_type: :incoming)
                                   .where('created_at < ?', message.created_at)
                                   .order(:created_at)
                                   .last

    last_customer_message&.created_at || message.conversation.created_at
  end
end
