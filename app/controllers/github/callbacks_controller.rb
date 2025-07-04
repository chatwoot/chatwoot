class Github::CallbacksController < ApplicationController
  include Github::IntegrationHelper

  def show
    # Log all received parameters for debugging
    Rails.logger.info("GitHub callback received parameters: #{params.to_unsafe_h}")
    Rails.logger.info("installation_id present: #{params[:installation_id].present?}")
    Rails.logger.info("code present: #{params[:code].present?}")
    Rails.logger.info("setup_action: #{params[:setup_action]}")
    Rails.logger.info("state present: #{params[:state].present?}")

    if params[:installation_id].present? && params[:code].present?
      Rails.logger.info('Handling installation with OAuth')
      # Both installation and OAuth code present - handle both
      handle_installation_with_oauth
    elsif params[:installation_id].present?
      Rails.logger.info('Handling installation only')
      # Only installation_id present - redirect to OAuth
      handle_installation
    else
      Rails.logger.info('Handling authorization only')
      # Only OAuth code present - handle authorization
      handle_authorization
    end
  rescue StandardError => e
    Rails.logger.error("Github callback error: #{e.message}")
    redirect_to fallback_redirect_uri
  end

  private

  def handle_installation_with_oauth
    Rails.logger.info("Processing installation with OAuth - installation_id: #{params[:installation_id]}, code: #{params[:code]}")
    # Handle both installation and OAuth in one go
    installation_id = params[:installation_id]

    @response = oauth_client.auth_code.get_token(
      params[:code],
      redirect_uri: "#{base_url}/github/callback"
    )

    handle_response(installation_id)
  end

  def handle_installation
    Rails.logger.info("Processing installation only - setup_action: #{params[:setup_action]}, installation_id: #{params[:installation_id]}")
    if params[:setup_action] == 'install'
      installation_id = params[:installation_id]

      redirect_to build_oauth_url(installation_id)
    else
      Rails.logger.error("Unknown setup_action: #{params[:setup_action]}")
      redirect_to github_integration_settings_url
    end
  end

  def handle_authorization
    Rails.logger.info("Processing authorization only - code: #{params[:code]}")
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
    settings = {
      token_type: parsed_body['token_type'],
      scope: parsed_body['scope']
    }

    # Add installation_id from parameter or session
    if installation_id
      settings[:installation_id] = installation_id
    elsif session[:github_installation_id]
      settings[:installation_id] = session[:github_installation_id]
    end

    # Use account from state parameter - this should work for both flows now
    target_account = account

    hook = target_account.hooks.new(
      access_token: parsed_body['access_token'],
      status: 'enabled',
      app_id: 'github',
      settings: settings
    )
    hook.save!

    # Clear session data
    session.delete(:github_installation_id)

    redirect_to github_redirect_uri
  rescue StandardError => e
    Rails.logger.error("Github callback error: #{e.message}")
    redirect_to fallback_redirect_uri
  end

  def account
    @account ||= Account.find(account_id)
  end

  def account_id
    # First try to get from state parameter (OAuth flow)
    return verify_github_token(params[:state]) if params[:state].present?

    # Fallback to hardcoded account 1 for installation flow (temporary)
    1
  end

  def github_redirect_uri
    "#{ENV.fetch('FRONTEND_URL', nil)}/app/accounts/#{account.id}/settings/integrations/github"
  end

  def github_integration_settings_url
    "#{ENV.fetch('FRONTEND_URL', nil)}/app/accounts/1/settings/integrations/github"
  end

  def fallback_redirect_uri
    if account_id
      github_redirect_uri
    else
      # Fallback if no account context available
      "#{ENV.fetch('FRONTEND_URL', nil)}/app/settings/integrations"
    end
  end

  def parsed_body
    @parsed_body ||= @response.response.parsed
  end

  def base_url
    ENV.fetch('FRONTEND_URL', 'http://localhost:3000')
  end
end
