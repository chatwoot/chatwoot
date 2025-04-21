class Github::CallbacksController < ApplicationController
  include Github::IntegrationHelper

  def show
    @response = oauth_client.auth_code.get_token(
      params[:code],
      redirect_uri: "#{base_url}/github/callback"
    )

    handle_response
  rescue StandardError => e
    Rails.logger.error("Github callback error: #{e.message}")
    redirect_to github_redirect_uri
  end

  private

  def oauth_client
    app_id = GlobalConfigService.load('GITHUB_CLIENT_ID', nil)
    app_secret = GlobalConfigService.load('GITHUB_CLIENT_SECRET', nil)

    OAuth2::Client.new(
      app_id,
      app_secret,
      {
        site: 'https://github.com',
        token_url: '/login/oauth/access_token',
        authorize_url: '/login/oauth/authorize'
      }
    )
  end

  def handle_response
    hook = account.hooks.new(
      access_token: parsed_body['access_token'],
      status: 'enabled',
      app_id: 'github',
      settings: {
        token_type: parsed_body['token_type'],
        scope: parsed_body['scope']
      }
    )
    hook.save!
    redirect_to github_redirect_uri
  rescue StandardError => e
    Rails.logger.error("Github callback error: #{e.message}")
    redirect_to github_redirect_uri
  end

  def account
    @account ||= Account.find(account_id)
  end

  def account_id
    return unless params[:state]

    verify_github_token(params[:state])
  end

  def github_redirect_uri
    "#{ENV.fetch('FRONTEND_URL', nil)}/app/accounts/#{account.id}/settings/integrations/github"
  end

  def parsed_body
    @parsed_body ||= @response.response.parsed
  end

  def base_url
    ENV.fetch('FRONTEND_URL', 'http://localhost:3000')
  end
end
