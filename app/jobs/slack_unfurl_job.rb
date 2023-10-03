class SlackUnfurlJob < ApplicationJob
  queue_as :low

  def perform(params)
    integration_hook = find_integration_hook(params)
    return unless integration_hook  # Handle if integration_hook is nil

    slack_client = build_slack_client(integration_hook)
    unfurl_service = build_unfurl_service(params, integration_hook)
    # Check the channel has access to the bot to unfurl the links
    response = slack_client.conversations_members(channel: params.dig(:event, :channel))

    unfurl_service.perform if response['ok']
  end

  private

  def find_integration_hook(params)
    # Find the integration hook by taking first link from the event params,
    # Assume that all the links are from the same account, how ever there is a possibility that the links are from different accounts.
    # Fix this issue later.
    url = extract_url(params)
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
end
