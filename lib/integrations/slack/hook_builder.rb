class Integrations::Slack::HookBuilder
  attr_reader :params

  def initialize(params)
    @params = params
  end

  def perform
    token = fetch_access_token

    hook = account.hooks.new(
      access_token: token,
      status: 'enabled',
      inbox_id: params[:inbox_id],
      hook_type: hook_type,
      app_id: 'slack'
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

  def fetch_access_token
    client = Slack::Web::Client.new
    slack_access = client.oauth_v2_access(
      client_id: account.slack&.client_id,
      client_secret: account.slack&.client_secret,
      code: params[:code],
      redirect_uri: Integrations::App.slack_integration_url
    )
    slack_access['access_token']
  end
end
