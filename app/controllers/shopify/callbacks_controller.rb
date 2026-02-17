class Shopify::CallbacksController < ApplicationController
  include Shopify::IntegrationHelper

  def show
    if chatwoot_initiated?
      handle_chatwoot_initiated_flow
    else
      handle_shopify_initiated_flow
    end
  rescue StandardError => e
    Rails.logger.error("Shopify callback error: #{e.message}")
    redirect_to error_redirect_url
  end

  private

  def chatwoot_initiated?
    verify_shopify_token(params[:state]).present?
  end

  def handle_chatwoot_initiated_flow
    @account_id = verify_shopify_token(params[:state])
    raise StandardError, 'Invalid state parameter' if account.blank?

    @response = oauth_client.auth_code.get_token(params[:code], redirect_uri: redirect_callback_uri)
    create_hook
    redirect_to shopify_integration_url
  end

  def handle_shopify_initiated_flow
    @response = oauth_client.auth_code.get_token(params[:code], redirect_uri: redirect_callback_uri)

    token_key = SecureRandom.hex(16)
    pending_data = { access_token: parsed_body['access_token'], shop: params[:shop], scope: parsed_body['scope'] }.to_json
    ::Redis::Alfred.setex("shopify_pending_install:#{token_key}", pending_data, 10.minutes)

    redirect_url = "settings/integrations/shopify?shopify_pending_install=#{token_key}"
    redirect_to "#{frontend_url}/app/login?redirect_url=#{CGI.escape(redirect_url)}", allow_other_host: true
  end

  def create_hook
    account.hooks.create!(
      app_id: 'shopify',
      access_token: parsed_body['access_token'],
      status: 'enabled',
      reference_id: params[:shop],
      settings: { scope: parsed_body['scope'] }
    )
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
    @account ||= Account.find(@account_id)
  end

  def redirect_callback_uri
    "#{frontend_url}/shopify/callback"
  end

  def shopify_integration_url
    "#{frontend_url}/app/accounts/#{account.id}/settings/integrations/shopify"
  end

  def error_redirect_url
    if @account_id
      begin
        "#{shopify_integration_url}?error=true"
      rescue ActiveRecord::RecordNotFound
        "#{frontend_url}?error=true"
      end
    else
      "#{frontend_url}?error=true"
    end
  end

  def frontend_url
    ENV.fetch('FRONTEND_URL', '')
  end
end
