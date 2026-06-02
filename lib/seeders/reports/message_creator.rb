# frozen_string_literal: true

require 'faker'
require 'active_support/testing/time_helpers'

class Seeders::Reports::MessageCreator
  include ActiveSupport::Testing::TimeHelpers

  MESSAGES_PER_CONVERSATION = 5

  def initialize(account:, agents:, conversation:)
    @account = account
    @agents = agents
    @conversation = conversation
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

  def create_incoming_message
    @conversation.messages.create!(
      account: @account,
      inbox: @conversation.inbox,
      message_type: :incoming,
      content: generate_message_content,
      sender: @conversation.contact
    )
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
