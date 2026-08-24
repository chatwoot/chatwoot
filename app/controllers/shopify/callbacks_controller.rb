class Shopify::CallbacksController < ApplicationController
  include Shopify::IntegrationHelper

  def show
    verify_account!
    verify_shop!

    @response = oauth_client.auth_code.get_token(
      params[:code],
      redirect_uri: '/shopify/callback'
    )

    handle_response
  rescue StandardError => e
    Rails.logger.error("Shopify callback error: #{e.message}")
    redirect_to "#{redirect_uri}?error=true"
  end

  private

  def verify_account!
    @account_id = verify_shopify_token(params[:state])
    raise StandardError, 'Invalid state parameter' if account.blank?
  end

  def verify_shop!
    @shop_domain = Shopify::ShopDomain.normalize(params[:shop])
    raise StandardError, 'Invalid shop domain' unless Shopify::ShopDomain.valid?(@shop_domain)
  end

  def handle_response
    hook = account.hooks.account_hooks.find_or_initialize_by(app_id: 'shopify')
    hook.assign_attributes(
      access_token: parsed_body['access_token'],
      status: 'enabled',
      reference_id: @shop_domain,
      settings: hook.settings.to_h.merge('scope' => parsed_body['scope'])
    )
    hook.save!
    after_shopify_connection(hook)

    redirect_to shopify_integration_url
  end

  def after_shopify_connection(_hook); end

  def parsed_body
    @parsed_body ||= @response.response.parsed
  end

  def oauth_client
    OAuth2::Client.new(
      client_id,
      client_secret,
      {
        site: "https://#{@shop_domain}",
        authorize_url: '/admin/oauth/authorize',
        token_url: '/admin/oauth/access_token'
      }
    )
  end

  def account
    @account ||= Account.find(@account_id)
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
end
Shopify::CallbacksController.prepend_mod_with('Shopify::CallbacksController')
