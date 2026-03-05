class Linear::CallbacksController < ApplicationController
  include Linear::IntegrationHelper

  def show
    return redirect_to(linear_redirect_uri) if params[:code].blank?

    @response = oauth_client.auth_code.get_token(
      params[:code],
      redirect_uri: "#{base_url}/linear/callback"
    )

    handle_response
  rescue StandardError => e
    Rails.logger.error("Linear callback error: #{e.message}")
    redirect_to linear_redirect_uri
  end

  private

  def oauth_client
    app_id = GlobalConfigService.load('LINEAR_CLIENT_ID', nil)
    app_secret = GlobalConfigService.load('LINEAR_CLIENT_SECRET', nil)

    OAuth2::Client.new(
      app_id,
      app_secret,
      {
        site: 'https://api.linear.app',
        token_url: '/oauth/token',
        authorize_url: '/oauth/authorize'
      }
    )
  end

  def handle_response
    hook = account.hooks.find_or_initialize_by(app_id: 'linear')
    hook.assign_attributes(
      access_token: parsed_body['access_token'],
      status: 'enabled',
      settings: integration_settings
    )
    hook.save!
    redirect_to linear_redirect_uri
  rescue StandardError => e
    Rails.logger.error("Linear callback error: #{e.message}")
    redirect_to linear_redirect_uri
  end

  def account
    @account ||= Account.find(account_id)
  end

  def account_id
    return unless params[:state]

    verify_linear_token(params[:state])
  end

  def linear_redirect_uri
    "#{ENV.fetch('FRONTEND_URL', nil)}/app/accounts/#{account.id}/settings/integrations/linear"
  end

  def parsed_body
    @parsed_body ||= @response.response.parsed
  end

  def integration_settings
    {
      token_type: parsed_body['token_type'],
      expires_in: parsed_body['expires_in'],
      expires_on: expires_on,
      scope: parsed_body['scope'],
      refresh_token: parsed_body['refresh_token']
    }.compact
  end

  def expires_on
    return if parsed_body['expires_in'].blank?

    (Time.current.utc + parsed_body['expires_in'].to_i.seconds).to_s
  end

  def base_url
    ENV.fetch('FRONTEND_URL', 'http://localhost:3000')
  end
end
