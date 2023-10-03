class SlackUnfurlJob < ApplicationJob
  queue_as :low

  def perform(params)
    integration_hook = find_integration_hook(params)
    return unless integration_hook

    slack_client = build_slack_client(integration_hook)

    return unless channel_has_access?(slack_client, params)

    unfurl_service = build_unfurl_service(params, integration_hook)

    unfurl_service.perform
  end

  private

  # Find the integration hook by taking first link from array of links
  # Assume that all the links are from the same account, how ever there is a possibility that the links are from different accounts.
  # TODO: Fix this edge case later
  def find_integration_hook(params)
    url = extract_url(params)
    return unless url

    account_id = extract_account_id(url)
    Integrations::Hook.find_by(account_id: account_id)
  end

  def extract_url(params)
    params.dig(:event, :links)&.first&.[](:url)
  end

  def extract_account_id(url)
    account_id_regex = %r{/accounts/(\d+)}
    match_data = url.match(account_id_regex)
    match_data[1] if match_data
  end

  def build_slack_client(hook)
    Slack::Web::Client.new(token: hook.access_token)
  end

  def build_unfurl_service(params, integration_hook)
    Integrations::Slack::SlackLinkUnfurlService.new(params: params, integration_hook: integration_hook)
  end

  # Check the channel has access to the bot to unfurl the links
  def channel_has_access?(slack_client, params)
    response = slack_client.conversations_members(channel: params.dig(:event, :channel))
    response['ok']
  end
end
