module Enterprise::ActionCableListener
  include Events::Types
  def copilot_message_created(event)
    copilot_message = event.data[:copilot_message]
    copilot_thread = copilot_message.copilot_thread
    account = copilot_thread.account
    user = copilot_thread.user

    broadcast(account, [user.pubsub_token], COPILOT_MESSAGE_CREATED, copilot_message.push_event_data)
  end

  def copilot_message_updated(event)
    copilot_message = event.data[:copilot_message]
    copilot_thread = copilot_message.copilot_thread

    broadcast(copilot_thread.account, [copilot_thread.user.pubsub_token], COPILOT_MESSAGE_UPDATED, copilot_message.push_event_data)
  end
end
