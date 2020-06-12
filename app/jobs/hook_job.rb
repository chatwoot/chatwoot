class HookJob < ApplicationJob
  queue_as :integrations

  def perform(hook, message)
    return unless hook.slack?

    Integrations::Slack::OutgoingMessageBuilder.perform(hook, message)
  rescue StandardError => e
    Raven.capture_exception(e)
  end
end
