class Integrations::Linear::HookBuilder
  attr_reader :params

  def initialize(params)
    @params = params
  end

  def perform
    token_data = fetch_access_token

    hook = account.hooks.new(
      access_token: token_data['access_token'],
      status: 'enabled',
      inbox_id: params[:inbox_id],
      app_id: 'linear',
      settings: {
        token_type: token_data['token_type'],
        expires_in: token_data['expires_in'],
        scope: token_data['scope']
      }
    )
    hook.save!
    hook
  end

  private

  def account
    params[:account]
  end

  def fetch_access_token
    response = HTTParty.post('https://api.linear.app/oauth/token',
                             body: {
                               code: params[:code],
                               client_id: ENV.fetch('LINEAR_CLIENT_ID', 'TEST_CLIENT_ID'),
                               client_secret: ENV.fetch('LINEAR_CLIENT_SECRET', 'TEST_CLIENT_SECRET'),
                               redirect_uri: linear_redirect_uri,
                               grant_type: 'authorization_code'
                             },
                             headers: { 'Content-Type' => 'application/x-www-form-urlencoded' })

    raise StandardError, response.parsed_response['error_description'] || 'Failed to authenticate with Linear' unless response.success?

    response.parsed_response
  end

  def linear_redirect_uri
    "#{ENV.fetch('FRONTEND_URL', nil)}/app/accounts/#{account.id}/settings/integrations/linear"
  end
end
