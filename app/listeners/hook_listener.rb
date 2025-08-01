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
    execute_hooks(event, contact)
  end

  def contact_updated(event)
    contact = extract_contact_and_account(event)[0]
    execute_hooks(event, contact)
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
end
