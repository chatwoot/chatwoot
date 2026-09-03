class Webhooks::ShopifyController < ActionController::API
  COMPLIANCE_TOPICS = %w[customers/data_request customers/redact shop/redact].freeze
  class CleanupIncomplete < StandardError; end

  before_action :ensure_shopify_enabled, unless: :compliance_event?
  before_action :verify_hmac!

  def events
    case request.headers['X-Shopify-Topic']
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
    shop_domain = params[:shop_domain]
    return if shop_domain.blank?

    hooks = Integrations::Hook.where(app_id: 'shopify', reference_id: shop_domain)
    hooks.find_each(&:destroy!)
    raise CleanupIncomplete, 'Shopify shop redaction is incomplete' if hooks.exists?
  end
end
