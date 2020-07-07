class HookJob < ApplicationJob
  queue_as :integrations

  def perform(hook, message)
    return unless hook.slack?

    Integrations::Slack::SendOnSlackService.new(message: message, hook: hook).perform
  rescue StandardError => e
    Raven.capture_exception(e)
  end
end
