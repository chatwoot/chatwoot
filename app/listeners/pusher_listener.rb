class PusherListener < BaseListener
  include Events::Types

  def conversation_created(event)
    conversation, account, timestamp = extract_conversation_and_account(event)
    members = conversation.inbox.members.pluck(:channel)
    Pusher.trigger(members, CONVERSATION_CREATED , conversation.push_event_data) if members.present?
  end

  def conversation_read(event)
    conversation, account, timestamp = extract_conversation_and_account(event)
    members = conversation.inbox.members.pluck(:channel)
    Pusher.trigger(members, CONVERSATION_READ , conversation.push_event_data) if members.present?
  end

  def message_created(event)
    message, account, timestamp = extract_message_and_account(event)
    conversation = message.conversation
    members = conversation.inbox.members.pluck(:channel)
    
    widget_user = conversation.sender.chat_channel
    members = members << widget_user
#    Pusher.trigger(members, MESSAGE_CREATED , message.push_event_data) if members.present?
  end

  def conversation_reopened(event)
    conversation, account, timestamp = extract_conversation_and_account(event)
    members = conversation.inbox.members.pluck(:channel)
    Pusher.trigger(members, CONVERSATION_REOPENED, conversation.push_event_data) if members.present?
  end

  def conversation_lock_toggle(event)
    conversation, account, timestamp = extract_conversation_and_account(event)
    members = conversation.inbox.members.pluck(:channel)
    Pusher.trigger(members, CONVERSATION_LOCK_TOGGLE, conversation.lock_event_data) if members.present?
  end

  def assignee_changed(event)
    conversation, account, timestamp = extract_conversation_and_account(event)
    members = conversation.inbox.members.pluck(:channel)
    Pusher.trigger(members, ASSIGNEE_CHANGED, conversation.push_event_data) if members.present?
  end

  private

  def push(channel, data)
    # Enqueue sidekiq job to push event to corresponding channel
  end
end
