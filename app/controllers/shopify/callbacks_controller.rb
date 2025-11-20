class Shopify::CallbacksController < ApplicationController
  include Shopify::IntegrationHelper

  def show
    log_debug("start state=#{params[:state]} code_present=#{params[:code].present?} shop=#{params[:shop]}")
    verify_account!

    @response = oauth_client.auth_code.get_token(
      params[:code],
      redirect_uri: '/shopify/callback'
    )

    log_debug("token response parsed=#{parsed_body.inspect}") if Rails.env.test?
    handle_response
  rescue StandardError => e
    log_debug("rescued #{e.class}: #{e.message}")
    redirect_to "#{redirect_uri}?error=true"
  end

  private

  def verify_account!
    @account_id = verify_shopify_token(params[:state])
    log_debug("verify_account! account_id=#{@account_id.inspect}")
    raise StandardError, 'Invalid state parameter' if account.blank?
  end

  def handle_response
    log_debug("creating hook for account_id=#{account.id} shop=#{params[:shop]}")

    account.hooks.create!(
      app_id: 'shopify',
      access_token: parsed_body['access_token'],
      status: 'enabled',
      reference_id: params[:shop],
      settings: {
        scope: parsed_body['scope']
      }
    )

    redirect_to shopify_integration_url
  end

  def parsed_body
    @parsed_body ||= @response.response.parsed
  end

  def oauth_client
    OAuth2::Client.new(
      client_id,
      client_secret,
      {
        site: "https://#{params[:shop]}",
        authorize_url: '/admin/oauth/authorize',
        token_url: '/admin/oauth/access_token'
      }
    )
  end

  def account
    @account ||= Account.find_by(id: @account_id).tap do |acct|
      log_debug("loaded account=#{acct&.id}")
    end
  end

  def account_id
    @account_id ||= params[:state].split('_').first
  end

  def shopify_integration_url
    "#{ENV.fetch('FRONTEND_URL', nil)}/app/accounts/#{account.id}/settings/integrations/shopify"
  end

  def redirect_uri
    return shopify_integration_url if account

    ENV.fetch('FRONTEND_URL', nil)
  end

  def log_debug(message)
    return unless Rails.env.test?

    Rails.logger.info("[SHOPIFY_CALLBACK] #{message}")
    # rubocop:disable Rails/Output
    puts "[SHOPIFY_CALLBACK] #{message}"
    # rubocop:enable Rails/Output
  end
end
