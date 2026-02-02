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
    Rails.logger.info "[HOOK_LISTENER] === execute_hooks called ==="
    Rails.logger.info "[HOOK_LISTENER] Event: #{event.name}"
    Rails.logger.info "[HOOK_LISTENER] Message ID: #{message.id}"
    Rails.logger.info "[HOOK_LISTENER] Message inbox ID: #{message.inbox&.id}"
    Rails.logger.info "[HOOK_LISTENER] Account ID: #{message.account&.id}"

    hooks_count = message.account.hooks.count
    Rails.logger.info "[HOOK_LISTENER] Total hooks in account: #{hooks_count}"

    message.account.hooks.find_each do |hook|
      Rails.logger.info "[HOOK_LISTENER] Checking hook ID: #{hook.id}, app_id: #{hook.app_id}, inbox_id: #{hook.inbox_id}, disabled: #{hook.disabled?}"

      # In case of dialogflow, we would have a hook for each inbox.
      # Which means we will execute the same hook multiple times if the below filter isn't there
      if hook.inbox.present? && hook.inbox != message.inbox
        Rails.logger.info "[HOOK_LISTENER] SKIPPED: Hook inbox (#{hook.inbox_id}) doesn't match message inbox (#{message.inbox&.id})"
        next
      end

      unless supported_hook_event?(hook, event.name)
        Rails.logger.info "[HOOK_LISTENER] SKIPPED: Hook #{hook.app_id} doesn't support event #{event.name}"
        next
      end

      Rails.logger.info "[HOOK_LISTENER] DISPATCHING: HookJob for hook #{hook.id} (#{hook.app_id})"
      HookJob.perform_later(hook, event.name, message: message)
    end
    Rails.logger.info "[HOOK_LISTENER] === execute_hooks completed ==="
  end

  def execute_account_hooks(event, account, event_data = {})
    account.hooks.account_hooks.find_each do |hook|
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
      'leadsquared' => ['contact.updated', 'conversation.created', 'conversation.resolved'],
      'socialwise_flow' => ['message.created', 'message.updated']
    }

    return false unless supported_events_map.key?(hook.app_id)

    supported_events_map[hook.app_id].include?(event_name)
  end
end
