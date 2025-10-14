class Github::CallbacksController < ApplicationController
  include Github::IntegrationHelper

  def show
    # Validate account context early for all flows that require it
    account if params[:code].present?

    if params[:installation_id].present? && params[:code].present?
      # Both installation and OAuth code present - handle both
      handle_installation_with_oauth
    elsif params[:installation_id].present?
      # Only installation_id present - redirect to OAuth
      handle_installation
    else
      # Only OAuth code present - handle authorization
      handle_authorization
    end
  rescue StandardError => e
    Rails.logger.error("Github callback error: #{e.message}")
    redirect_to fallback_redirect_uri
  end

  private

  def handle_installation_with_oauth
    # Handle both installation and OAuth in one go
    installation_id = params[:installation_id]

    @response = oauth_client.auth_code.get_token(
      params[:code],
      redirect_uri: "#{base_url}/github/callback"
    )

    handle_response(installation_id)
  end

  def handle_installation
    if params[:setup_action] == 'install'
      installation_id = params[:installation_id]

      redirect_to build_oauth_url(installation_id)
    else
      Rails.logger.error("Unknown setup_action: #{params[:setup_action]}")
      redirect_to github_integration_settings_url
    end
  end

  def handle_authorization
    @response = oauth_client.auth_code.get_token(
      params[:code],
      redirect_uri: "#{base_url}/github/callback"
    )

    handle_response
  end

  def build_oauth_url(installation_id)
    GlobalConfigService.load('GITHUB_CLIENT_ID', nil)

    # Store installation_id in session for later use
    session[:github_installation_id] = installation_id

    # For now, redirect to a page that will initiate OAuth with proper account context
    # This is a temporary solution until we have a proper account-agnostic setup
    "#{ENV.fetch('FRONTEND_URL', nil)}/app/accounts/1/settings/integrations/github?setup_action=install&installation_id=#{installation_id}"
  end

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

  def handle_response(installation_id = nil)
    settings = build_hook_settings(installation_id)
    hook = create_integration_hook(settings)
    hook.save!

    cleanup_session_data
    redirect_to github_redirect_uri
  rescue StandardError => e
    Rails.logger.error("Github callback error: #{e.message}")
    redirect_to fallback_redirect_uri
  end

  def build_hook_settings(installation_id)
    settings = {
      token_type: parsed_body['token_type'],
      scope: parsed_body['scope']
    }

    settings[:installation_id] = installation_id || session[:github_installation_id]
    settings.compact
  end

  def create_integration_hook(settings)
    account.hooks.new(
      access_token: parsed_body['access_token'],
      status: 'enabled',
      app_id: 'github',
      settings: settings
    )
  end

  def cleanup_session_data
    session.delete(:github_installation_id)
  end

  def account
    @account ||= account_from_state
  end

  def account_from_state
    raise ActionController::BadRequest, 'Missing state variable' if params[:state].blank?

    # Try signed GlobalID first (installation flow)
    account = GlobalID::Locator.locate_signed(params[:state])
    return account if account

    # Fallback to JWT token (direct OAuth flow)
    account_id = verify_github_token(params[:state])
    return Account.find(account_id) if account_id

    raise 'Invalid or expired state'
  rescue StandardError
    raise ActionController::BadRequest, 'Invalid account context'
  end

  def github_redirect_uri
    "#{ENV.fetch('FRONTEND_URL', nil)}/app/accounts/#{account.id}/settings/integrations/github"
  end

  def github_integration_settings_url
    "#{ENV.fetch('FRONTEND_URL', nil)}/app/accounts/1/settings/integrations/github"
  end

  def fallback_redirect_uri
    github_redirect_uri
  rescue StandardError
    # Fallback if no account context available
    "#{ENV.fetch('FRONTEND_URL', nil)}/app/settings/integrations"
  end

  def parsed_body
    @parsed_body ||= @response.response.parsed
  end

  def base_url
    ENV.fetch('FRONTEND_URL', 'http://localhost:3000')
  end
end
