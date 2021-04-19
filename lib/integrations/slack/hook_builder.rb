class Integrations::Slack::HookBuilder
  attr_reader :params

  def initialize(params)
    @params = params
  end

  def perform
    @slack_access = exchange_temporary_code

    hook = account.hooks.new(
      access_token: @slack_access['access_token'],
      status: 'enabled',
      inbox_id: params[:inbox_id],
      hook_type: hook_type,
      app_id: 'slack',
      reference_id: reference_id
    )

    hook.save!
    hook
  end

  private

  def account
    params[:account]
  end

  def hook_type
    params[:inbox_id] ? 'inbox' : 'account'
  end

  def exchange_temporary_code
    Slack::Web::Client.new.oauth_v2_access(
      client_id: ENV.fetch('SLACK_CLIENT_ID', 'TEST_CLIENT_ID'),
      client_secret: ENV.fetch('SLACK_CLIENT_SECRET', 'TEST_CLIENT_SECRET'),
      code: params[:code],
      redirect_uri: Integrations::App.slack_integration_url
    )
  end

  def reference_id
    return if @slack_access['incoming_webhook'].blank?
    return if @slack_access['incoming_webhook']['channel'].blank?
    return if @slack_access['incoming_webhook']['channel'].split('#')[1].blank?

    @slack_access['incoming_webhook']['channel_id']
  end
end
