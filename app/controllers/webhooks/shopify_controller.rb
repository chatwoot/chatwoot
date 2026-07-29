class Webhooks::ShopifyController < ActionController::API
  COMPLIANCE_TOPICS = %w[customers/data_request customers/redact shop/redact].freeze
  class CleanupIncomplete < StandardError; end

  before_action :ensure_shopify_enabled, unless: :compliance_event?
  before_action :verify_hmac!

  def events
    case request.headers['X-Shopify-Topic']
    when 'app/uninstalled'
      handle_app_uninstalled
    when 'shop/redact'
      handle_shop_redact
    end

    head :ok
  end

  private

  def ensure_shopify_enabled
    head :not_found unless Shopify::FeatureGate.enabled?
  end

  def compliance_event?
    COMPLIANCE_TOPICS.include?(request.headers['X-Shopify-Topic'])
  end

  def verify_hmac!
    secret = GlobalConfigService.load('SHOPIFY_CLIENT_SECRET', nil)
    return head :unauthorized if secret.blank?

    data = request.body.read
    request.body.rewind

    hmac_header = request.headers['X-Shopify-Hmac-SHA256']
    return head :unauthorized if hmac_header.blank?

    computed = Base64.strict_encode64(OpenSSL::HMAC.digest('SHA256', secret, data))
    return head :unauthorized unless ActiveSupport::SecurityUtils.secure_compare(computed, hmac_header)
  end

  def handle_shop_redact
    hooks = shopify_hooks(params[:shop_domain])
    hooks.find_each do |hook|
      Shopify::UninstallationService.new(hook: hook).perform
      hook.destroy! if hook.persisted?
    end
    raise CleanupIncomplete, 'Shopify shop redaction is incomplete' if hooks.exists?
  end

  def handle_app_uninstalled
    triggered_at = Time.iso8601(request.headers.fetch('X-Shopify-Triggered-At'))

    shopify_hooks(params[:myshopify_domain]).find_each do |hook|
      Shopify::UninstallationService.new(hook: hook, occurred_at: triggered_at).perform
    end
  end

  def shopify_hooks(shop_domain)
    normalized_domain = Shopify::ShopDomain.normalize(shop_domain)
    return Integrations::Hook.none unless Shopify::ShopDomain.valid?(normalized_domain)

    Integrations::Hook.where(app_id: 'shopify').where('LOWER(reference_id) = ?', normalized_domain)
  end
end
