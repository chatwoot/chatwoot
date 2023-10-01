class SlackUnfurlJob < ApplicationJob
  queue_as :low

  def perform(params, integration_hook)
    Integrations::Slack::SlackLinkUnfurlService.new(params: params, integration_hook: integration_hook).perform
  end
end
