class HookListener < BaseListener
  def message_created(event)
    message = extract_message_and_account(event)[0]
    return unless message.reportable?

    message.account.hooks.each do |hook|
      HookJob.perform_later(hook, message)
    end
  end
end
