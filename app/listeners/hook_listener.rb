class HookListener < BaseListener
  def message_created(event)
    message = extract_message_and_account(event)[0]

    execute_hooks(event, message)
  end

  def message_updated(event)
    message = extract_message_and_account(event)[0]

    execute_hooks(event, message)
  end

  def contact_created(event)
    contact = extract_contact_and_account(event)[0]
    execute_account_hooks(event, contact.account, contact: contact)
  end

  def contact_updated(event)
    contact = extract_contact_and_account(event)[0]
    execute_account_hooks(event, contact.account, contact: contact)
  end

  def conversation_created(event)
    conversation = extract_conversation_and_account(event)[0]
    execute_account_hooks(event, conversation.account, conversation: conversation)
  end

  def conversation_resolved(event)
    conversation = extract_conversation_and_account(event)[0]
    # Only trigger for status changes is resolved
    return unless conversation.status == 'resolved'

    execute_account_hooks(event, conversation.account, conversation: conversation)
  end

  private

  def execute_hooks(event, message)
    message.account.hooks.each do |hook|
      # In case of dialogflow, we would have a hook for each inbox.
      # Which means we will execute the same hook multiple times if the below filter isn't there
      next if hook.inbox.present? && hook.inbox != message.inbox

      HookJob.perform_later(hook, event.name, message: message)
    end
  end

  def execute_account_hooks(event, account, event_data = {})
    account.hooks.account_hooks.find_each do |hook|
      HookJob.perform_later(hook, event.name, event_data)
    end
  end
end
