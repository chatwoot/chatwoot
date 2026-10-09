# What the conversation payload shows from a conversation's messages.
class Conversations::MessageSummary
  attr_reader :unread_count

  def initialize(last_message:, last_non_activity_message:, unread_count:)
    @last_message = last_message
    @last_non_activity_message = last_non_activity_message
    @unread_count = unread_count
  end

  def last_message_data
    @last_message_data ||= @last_message&.push_event_data(unread_count: unread_count)
  end

  # Usually the same message as the latest one, which is then serialized only once.
  def last_non_activity_message_data
    return last_message_data if @last_non_activity_message == @last_message

    @last_non_activity_message&.push_event_data(unread_count: unread_count)
  end
end
