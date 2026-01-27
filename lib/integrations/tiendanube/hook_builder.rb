class Integrations::Tiendanube::HookBuilder
  attr_reader :params

  def initialize(params)
    @params = params
  end

  def perform
    response = fetch_access_token
    
    hook = account.hooks.new(
      app_id: 'tiendanube',
      access_token: response['access_token'],
      reference_id: response['user_id'],
      status: 'enabled'
    )

    hook.save!
    hook
  end

  private

  def account
    params[:account]
  end

  def fetch_access_token
    response = HTTParty.post(
      'https://www.tiendanube.com/apps/authorize/token',
      headers: { 'Content-Type' => 'application/json' },
      body: {
        client_id: GlobalConfigService.load('TIENDANUBE_CLIENT_ID'),
        client_secret: GlobalConfigService.load('TIENDANUBE_CLIENT_SECRET'),
        grant_type: 'authorization_code',
        code: params[:code]
      }.to_json
    )

    parsed = JSON.parse(response.body)

    if parsed['access_token'].blank? || parsed['user_id'].blank?
      raise StandardError, "Tiendanube OAuth failed: #{parsed}"
    end

    parsed
  end
end
