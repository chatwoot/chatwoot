class Integrations::Shopify::ClientService
  include Shopify::IntegrationHelper

  API_VERSION = '2025-01'.freeze

  def initialize(account:)
    @account = account
  end

  # rubocop:disable Metrics/AbcSize
  def fetch_client
    Rails.logger.info("[Integrations::Shopify::ClientService] fetch_client account_id=#{@account.id}")
    unless hook
      Rails.logger.warn("[Integrations::Shopify::ClientService] not_connected account_id=#{@account.id}")
      return failure(:not_connected, 'Shopify integration is not connected.')
    end

    setup_shopify_context

    Rails.logger.info(
      "[Integrations::Shopify::ClientService] connected account_id=#{@account.id} " \
      "shop=#{hook.reference_id} scopes=#{granted_scopes.join(',')}"
    )

    success(
      client: ShopifyAPI::Clients::Rest::Admin.new(session: shopify_session),
      hook: hook,
      scopes: granted_scopes
    )
  rescue StandardError => e
    Rails.logger.error("[Integrations::Shopify::ClientService] #{e.class}: #{e.message}")
    failure(:provider_error, 'Unable to communicate with Shopify.')
  end
  # rubocop:enable Metrics/AbcSize

  def scopes_include?(*required_scopes)
    required_scopes.flatten.all? { |scope| granted_scopes.include?(scope) }
  end

  def granted_scopes
    parse_scopes(scope_value)
  end

  private

  def hook
    @hook ||= Integrations::Hook.find_by(account: @account, app_id: 'shopify', status: :enabled)
  end

  def setup_shopify_context
    raise 'Shopify client credentials are missing.' if client_id.blank? || client_secret.blank?

    ShopifyAPI::Context.setup(
      api_key: client_id,
      api_secret_key: client_secret,
      api_version: API_VERSION,
      scope: REQUIRED_SCOPES.join(','),
      is_embedded: true,
      is_private: false
    )
  end

  def shopify_session
    ShopifyAPI::Auth::Session.new(shop: hook.reference_id, access_token: hook.access_token)
  end

  def scope_value
    settings = hook&.settings || {}
    settings['scope'] || settings[:scope]
  end

  def parse_scopes(raw_scope)
    raw_scope.to_s.split(',').map(&:strip).reject(&:blank?).uniq
  end

  def success(data)
    { ok: true, data: data }
  end

  def failure(code, message)
    { ok: false, error: { code: code, message: message } }
  end
end
