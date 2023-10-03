class SlackUnfurlJob < ApplicationJob
  queue_as :low

  def perform(params)
    integration_hook = find_integration_hook(params)
    slack_client = build_slack_client(integration_hook)
    unfurl_service = Integrations::Slack::SlackLinkUnfurlService.new(params: params, integration_hook: integration_hook)

    slack_client.conversations_members(channel: params[:event][:channel])

    unfurl_service.perform
  end

  private

  def find_integration_hook(params)
    event_links = params.dig(:event, :links)
    url = event_links.first[:url]
    account_id = extract_account_id(url)
    Integrations::Hook.find_by(account_id: account_id)
  end

  def extract_account_id(url)
    account_id_regex = %r{/accounts/(\d+)}
    match_data = url.match(account_id_regex)
    match_data[1] if match_data
  end

  def build_slack_client(hook)
    Slack::Web::Client.new(token: hook.access_token)
  end
end
