class Shopify::CallbacksController < ApplicationController
  include Shopify::IntegrationHelper

  def show
    @account_id = verified_account_id
    raise StandardError, 'Shopify authorization was denied' if params[:error].present?

    handle_chatwoot_initiated_flow
  rescue StandardError => e
    Rails.logger.error("Shopify callback error: #{e.message}")
    redirect_to error_redirect_url, allow_other_host: true
  end

  private

  def handle_chatwoot_initiated_flow
    raise StandardError, 'Invalid state parameter' if account.blank?

    ensure_shopify_enabled!(account: account)
    raise StandardError, 'Invalid HMAC signature' unless valid_hmac?
    raise StandardError, 'Invalid shop domain' unless valid_shop_domain?

    @shopify_installation_generation = Shopify::InstallationGeneration.current(account)
    exchange_and_create_hook
    redirect_to shopify_integration_url, allow_other_host: true
  end

  def exchange_and_create_hook
    shop_generation = Shopify::PendingInstallation.generation(shop: params[:shop])
    exchange_access_token
    with_current_shop_generation(shop_generation) { create_hook }
  end

  def with_current_shop_generation(expected_generation)
    Shopify::InstallationGeneration.with_shop_lock(params[:shop]) do
      unless expected_generation.to_i == Shopify::PendingInstallation.generation(shop: params[:shop])
        raise StandardError, 'Shopify installation changed during authorization'
      end

      yield
    end
  end

  def exchange_access_token
    @response = oauth_client.auth_code.get_token(params[:code], redirect_uri: redirect_callback_uri)
  end

  def create_hook
    Shopify::InstallationGeneration.with_current!(account, @shopify_installation_generation) do
      hook = account.hooks.find_or_initialize_by(app_id: 'shopify', reference_id: Shopify::ShopDomain.normalize(params[:shop]))
      hook.update!(shopify_hook_attributes)
    end
  end

  def shopify_hook_attributes
    {
      app_id: 'shopify',
      access_token: parsed_body['access_token'],
      status: 'enabled',
      reference_id: params[:shop],
      settings: shopify_hook_settings
    }
  end

  def shopify_hook_settings
    {
      scope: parsed_body['scope'],
      connected_at: Time.current.utc.iso8601(6),
      installation_id: SecureRandom.uuid
    }
  end

  def parsed_body
    @parsed_body ||= begin
      parsed = @response.response.parsed
      # Handle both SnakyHash (production) and regular Hash (tests)
      {
        'access_token' => parsed.respond_to?(:access_token) ? parsed.access_token : parsed['access_token'],
        'scope' => parsed.respond_to?(:scope) ? parsed.scope : parsed['scope']
      }
    end
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

  def account = (@account ||= Account.find(@account_id))

  def verified_account_id
    return unless params[:state].to_s.count('.') == 2

    @verified_account_id ||= verify_shopify_token(params[:state])
  end

  def ensure_shopify_enabled!(account: nil)
    raise StandardError, 'Shopify integration is disabled' unless Shopify::FeatureGate.enabled?(account: account)
  end

  def redirect_callback_uri = "#{frontend_url}/shopify/callback"

  def shopify_integration_url = "#{frontend_url}/app/accounts/#{account.id}/settings/integrations/shopify"

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

  def frontend_url = ENV.fetch('FRONTEND_URL', '')

  def valid_shop_domain?
    return false if params[:shop].blank?

    # Shopify shop domains must match: *.myshopify.com or *.myshopify.io (for dev shops)
    params[:shop].match?(/\A[a-zA-Z0-9][a-zA-Z0-9\-]*\.myshopify\.(com|io)\z/)
  end

  def valid_hmac?
    hmac = params[:hmac].to_s
    return false unless hmac.match?(/\A[0-9a-f]{64}\z/)

    # Shopify HMAC validation
    # Reference: https://shopify.dev/docs/apps/build/authentication-authorization/get-access-tokens
    query_params = request.query_parameters.except('hmac')
    query_string = URI.encode_www_form(query_params.sort)

    # Compute HMAC-SHA256
    computed_hmac = OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new('SHA256'), client_secret, query_string)

    ActiveSupport::SecurityUtils.secure_compare(computed_hmac, hmac)
  end
end
