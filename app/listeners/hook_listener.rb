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

  def execute_hooks(event, account, event_data = {})
    hooks_scope = event_data[:message].present? ? account.hooks : account.hooks.account_hooks
    
    hooks_scope.each do |hook|
      # For message hooks, filter by inbox if present
      if event_data[:message].present?
        message = event_data[:message]
        next if hook.inbox.present? && hook.inbox != message.inbox
      end
      
      next unless supported_hook_event?(hook, event.name)

      HookJob.perform_later(hook, event.name, event_data)
    end
  end

  def supported_hook_event?(hook, event_name)
    return false if hook.disabled?

    supported_events_map = {
      'slack' => ['message.created'],
      'dialogflow' => ['message.created', 'message.updated'],
      'google_translate' => ['message.created'],
      'leadsquared' => ['contact.updated', 'conversation.created', 'conversation.resolved']
    }

    return false unless supported_events_map.key?(hook.app_id)

    supported_events_map[hook.app_id].include?(event_name)
  end
end
