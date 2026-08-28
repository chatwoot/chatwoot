class Shopify::CallbacksController < ApplicationController
  include Shopify::IntegrationHelper

  def show
    if chatwoot_initiated?
      handle_chatwoot_initiated_flow
    elsif params[:code].blank?
      handle_shopify_initiated_without_code
    else
      handle_shopify_initiated_flow
    end
  rescue StandardError => e
    Rails.logger.error("Shopify callback error: #{e.message}")
    redirect_to error_redirect_url
  end

  private

  def chatwoot_initiated? = verified_account_id.present?

  def handle_chatwoot_initiated_flow
    @account_id = verified_account_id
    raise StandardError, 'Invalid state parameter' if account.blank?

    ensure_shopify_enabled!(account: account)
    raise StandardError, 'Invalid HMAC signature' unless valid_hmac?

    @shopify_installation_generation = Shopify::InstallationGeneration.current(account)
    exchange_access_token
    create_hook
    redirect_to shopify_integration_url
  end

  def handle_shopify_initiated_flow
    prepare_shopify_initiated_flow
    exchange_access_token

    if @account
      reconnect_existing_shopify_account
      return redirect_to existing_account_redirect_url
    end

    token_key = Shopify::PendingInstallation.create(
      access_token: parsed_body['access_token'],
      shop: params[:shop],
      scope: parsed_body['scope']
    )

    redirect_to "#{frontend_url}/app/auth/signup?shopify_pending_install=#{CGI.escape(token_key)}", allow_other_host: true
  end

  def handle_shopify_initiated_without_code
    prepare_shopify_initiated_flow
    hook = @account&.hooks&.find_by(app_id: 'shopify')
    return redirect_to existing_account_redirect_url if hook&.enabled? && hook.access_token.present?

    authorization_url = oauth_client.auth_code.authorize_url(
      redirect_uri: redirect_callback_uri,
      scope: Shopify::IntegrationHelper::REQUIRED_SCOPES.join(',')
    )
    redirect_to authorization_url, allow_other_host: true
  end

  def prepare_shopify_initiated_flow
    ensure_shopify_enabled!
    raise StandardError, 'Invalid shop domain' unless valid_shop_domain?
    raise StandardError, 'Invalid HMAC signature' unless valid_hmac?

    load_existing_shopify_account
  end

  def exchange_access_token
    @response = oauth_client.auth_code.get_token(params[:code], redirect_uri: redirect_callback_uri)
  end

  def load_existing_shopify_account
    @account = existing_shopify_account
    return unless @account

    @account_id = account.id
    ensure_shopify_enabled!(account: account)
    @shopify_installation_generation = Shopify::InstallationGeneration.current(account)
  end

  def create_hook
    Shopify::InstallationGeneration.with_current!(account, @shopify_installation_generation) do
      account.hooks.create!(shopify_hook_attributes)
    end
  end

  def reconnect_existing_shopify_account
    Shopify::InstallationGeneration.with_current!(account, @shopify_installation_generation) do
      loop do
        hook = account.hooks.find_by(app_id: 'shopify')
        unless hook
          account.hooks.create!(shopify_hook_attributes)
          break
        end

        begin
          hook.with_lock { hook.update!(shopify_hook_attributes) }
          break
        rescue ActiveRecord::RecordNotFound
          next
        end
      end
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

  def existing_shopify_account
    existing_shopify_hook&.account || shopify_billed_account_by_snapshot
  end

  def existing_shopify_hook
    @existing_shopify_hook ||=
      Integrations::Hook.where(app_id: 'shopify').find_by('LOWER(reference_id) = ?', Shopify::ShopDomain.normalize(params[:shop]))
  end

  def shopify_billed_account_by_snapshot
    Account
      .where("internal_attributes ->> 'billing_provider' = ?", 'shopify')
      .where("internal_attributes ->> 'signup_source' = ?", 'shopify')
      .find_by("custom_attributes #>> '{shopify_subscription_snapshot,shop_domain}' = ?",
               Shopify::ShopDomain.normalize(params[:shop]))
  end

  def existing_account_redirect_url
    return shopify_billing_url if account.billing_provider == 'shopify' && account.signup_source == 'shopify'

    shopify_integration_url
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

  def verified_account_id = (@verified_account_id ||= verify_shopify_token(params[:state]))

  def ensure_shopify_enabled!(account: nil)
    raise StandardError, 'Shopify integration is disabled' unless Shopify::FeatureGate.enabled?(account: account)
  end

  def redirect_callback_uri = "#{frontend_url}/shopify/callback"

  def shopify_integration_url = "#{frontend_url}/app/accounts/#{account.id}/settings/integrations/shopify"

  def shopify_billing_url = "#{frontend_url}/app/accounts/#{account.id}/settings/billing?shop=#{CGI.escape(params[:shop])}"

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
    return false if params[:hmac].blank?

    # Shopify HMAC validation
    # Reference: https://shopify.dev/docs/apps/build/authentication-authorization/get-access-tokens
    hmac = params[:hmac]

    # Build query string from params, excluding hmac and Rails-added params
    query_params = params.except(:hmac, :controller, :action).to_unsafe_h
    query_string = query_params.sort.map { |k, v| "#{k}=#{v}" }.join('&')

    # Compute HMAC-SHA256
    computed_hmac = OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new('SHA256'), client_secret, query_string)

    ActiveSupport::SecurityUtils.secure_compare(computed_hmac, hmac)
  end
end
