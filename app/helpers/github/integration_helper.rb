module Github::IntegrationHelper
  def github_integration_url(account_id)
    "#{ENV.fetch('FRONTEND_URL', nil)}/github/callback?account_id=#{account_id}"
  end

  def github_oauth_url(account_id)
    client_id = GlobalConfigService.load('GITHUB_CLIENT_ID', nil)
    return nil unless client_id

    params = {
      client_id: client_id,
      redirect_uri: github_integration_url(account_id),
      scope: 'repo',
      state: generate_state_token(account_id)
    }

    "https://github.com/login/oauth/authorize?#{params.to_query}"
  end

  def github_configured?
    GlobalConfigService.load('GITHUB_CLIENT_ID', nil).present? &&
      GlobalConfigService.load('GITHUB_CLIENT_SECRET', nil).present?
  end

  def github_integration_enabled?(account)
    return false unless github_configured?

    account.hooks.exists?(app_id: 'github', status: 'enabled')
  end

  def github_repositories(access_token)
    return [] unless access_token

    response = HTTParty.get('https://api.github.com/user/repos', {
                              headers: {
                                'Authorization' => "token #{access_token}",
                                'Accept' => 'application/vnd.github.v3+json'
                              },
                              query: {
                                per_page: 100,
                                sort: 'updated'
                              }
                            })

    if response.success?
      JSON.parse(response.body)
    else
      []
    end
  rescue StandardError => e
    Rails.logger.error "GitHub API error: #{e.message}"
    []
  end

  private

  def generate_state_token(account_id)
    payload = {
      account_id: account_id,
      timestamp: Time.current.to_i
    }

    JWT.encode(payload, Rails.application.secret_key_base, 'HS256')
  end

  def verify_state_token(state)
    JWT.decode(state, Rails.application.secret_key_base, true, { algorithm: 'HS256' })
  rescue JWT::DecodeError
    nil
  end
end