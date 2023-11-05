class SlackUnfurlJob < ApplicationJob
  queue_as :low

  def perform(params)
    @params = params
    set_integration_hook

    return unless channel_has_access

    Integrations::Slack::SlackLinkUnfurlService.new(params: @params, integration_hook: @integration_hook).perform
  end

  private

  # Find the integration hook by taking first link from array of links
  # Assume that all the links are from the same account, how ever there is a possibility that the links are from different accounts.
  # TODO: Fix this edge case later
  def set_integration_hook
    url = extract_url
    return unless url

    account_id = extract_account_id(url)
    @integration_hook = Integrations::Hook.find_by(account_id: account_id, app_id: 'slack')
  end

  def extract_url
    @params.dig(:event, :links)&.first&.[](:url)
  end

  def extract_account_id(url)
    account_id_regex = %r{/accounts/(\d+)}
    match_data = url.match(account_id_regex)
    match_data[1] if match_data
  end

  # Check the channel has access to the bot to unfurl the links
  def channel_has_access
    return if @integration_hook.blank?

    slack_client = Slack::Web::Client.new(token: @integration_hook.access_token)
    response = slack_client.conversations_members(channel: @params.dig(:event, :channel))
    response['ok']
  rescue Slack::Web::Api::Errors::ChannelNotFound => e
    # The link unfurl event will not work for private channels and other accounts channels
    # So we can ignore the error
    Rails.logger.error "Exception in SlackUnfurlJob: #{e.message}"
    false
  end
end
