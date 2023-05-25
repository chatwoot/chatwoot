class SendOnSlackJob < ApplicationJob
  queue_as :medium

  def perform(message, hook)
    Integrations::Slack::SendOnSlackService.new(message: message, hook: hook).perform
  end
end
