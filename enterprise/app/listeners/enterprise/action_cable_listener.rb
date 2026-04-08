module Enterprise::ActionCableListener
  include Events::Types
  def copilot_message_created(event)
    copilot_message = event.data[:copilot_message]
    copilot_thread = copilot_message.copilot_thread
    account = copilot_thread.account
    user = copilot_thread.user

    broadcast(account, [user.pubsub_token], COPILOT_MESSAGE_CREATED, copilot_message.push_event_data)
  end

  def captain_document_updated(event)
    document = event.data[:captain_document]
    account = document.account
    tokens = user_tokens(account, account.agents)

    broadcast(account, tokens, CAPTAIN_DOCUMENT_UPDATED, document.push_event_data)
  end
end
