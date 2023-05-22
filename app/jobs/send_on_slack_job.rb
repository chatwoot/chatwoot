class SendOnSlackJob < ApplicationJob
  queue_as :medium
  pattr_initialize [:message!, :hook!]

  def perform
    Integrations::Slack::SendOnSlackService.new(message: message, hook: hook).perform
  end
end
