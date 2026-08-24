class Integrations::Slack::HookBuilder
  attr_reader :params

  def initialize(params)
    @params = params
  end

  def perform
    slack_access = fetch_access
    token = slack_access.fetch('access_token')
    identity = validate_access_token(token)
    hook = account.hooks.account_hooks.find_or_initialize_by(app_id: 'slack')
    hook.assign_attributes(
      access_token: token,
      settings: slack_settings(hook, slack_access, identity)
    )
    if hook.new_record?
      hook.inbox_id = params[:inbox_id]
      hook.status = 'disabled'
    end
    hook.save!
    hook
  end

  private

  def account
    params[:account]
  end

  def fetch_access
    client = Slack::Web::Client.new
    client.oauth_v2_access(
      client_id: GlobalConfigService.load('SLACK_CLIENT_ID', 'TEST_CLIENT_ID'),
      client_secret: GlobalConfigService.load('SLACK_CLIENT_SECRET', 'TEST_CLIENT_SECRET'),
      code: params[:code],
      redirect_uri: slack_redirect_uri
    ).to_h.deep_stringify_keys
  end

  def validate_access_token(token)
    Slack::Web::Client.new(token: token).auth_test.to_h.deep_stringify_keys
  end

  def slack_settings(hook, slack_access, identity)
    settings = hook.settings.to_h.stringify_keys.merge(
      'scope' => slack_access['scope'],
      'token_type' => slack_access['token_type'],
      'workspace_id' => identity['team_id'] || slack_access.dig('team', 'id'),
      'workspace_name' => identity['team'] || slack_access.dig('team', 'name'),
      'bot_user_id' => slack_access['bot_user_id'] || identity['user_id'],
      'validated_at' => Time.current.utc.iso8601
    ).compact
    settings['catalog_connected'] = true if params[:catalog]
    settings
  end

  def slack_redirect_uri
    "#{ENV.fetch('FRONTEND_URL', nil)}/app/accounts/#{account.id}/settings/integrations/slack"
  end
end
