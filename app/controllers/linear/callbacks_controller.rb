class Linear::CallbacksController < ApplicationController
  include Linear::IntegrationHelper

  def show
    return redirect_to(safe_linear_redirect_uri) if params[:code].blank? || account_id.blank?

    @response = oauth_client.auth_code.get_token(
      params[:code],
      redirect_uri: "#{base_url}/linear/callback"
    )

    handle_response
  rescue StandardError => e
    Rails.logger.error("Linear callback error: #{e.message}")
    redirect_to safe_linear_redirect_uri
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
    raise ArgumentError, 'Missing access token in Linear OAuth response' if parsed_body['access_token'].blank?

    hook = account.hooks.find_or_initialize_by(app_id: 'linear')
    hook.assign_attributes(
      access_token: parsed_body['access_token'],
      status: 'enabled',
      settings: merged_integration_settings(hook.settings)
    )
    hook.save!
    redirect_to linear_redirect_uri
  rescue StandardError => e
    Rails.logger.error("Linear callback error: #{e.message}")
    redirect_to safe_linear_redirect_uri
  end

  def account
    @account ||= Account.find(account_id)
  end

  def account_id
    return @account_id if instance_variable_defined?(:@account_id)

    @account_id = params[:state].present? ? verify_linear_token(params[:state]) : nil
  end

  def linear_redirect_uri
    "#{ENV.fetch('FRONTEND_URL', nil)}/app/accounts/#{account.id}/settings/integrations/linear"
  end

  def safe_linear_redirect_uri
    return base_url if account_id.blank?

    linear_redirect_uri
  rescue StandardError
    base_url
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

  def merged_integration_settings(existing_settings)
    existing_settings.to_h.with_indifferent_access.merge(integration_settings)
  end

  def expires_on
    return if parsed_body['expires_in'].blank?

    (Time.current.utc + parsed_body['expires_in'].to_i.seconds).to_s
  end

  def base_url
    ENV.fetch('FRONTEND_URL', 'http://localhost:3000')
  end
end
