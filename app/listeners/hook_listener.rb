class HookListener < BaseListener
  def message_created(event)
    message = extract_message_and_account(event)[0]
    return unless message.webhook_sendable?

    message.account.hooks.each do |hook|
      HookJob.perform_later(hook, event.name, message: message)
    end
  end

  def message_updated(event)
    message = extract_message_and_account(event)[0]
    return unless message.webhook_sendable?

    message.account.hooks.each do |hook|
      HookJob.perform_later(hook, event.name, message: message)
    end
  end
end
