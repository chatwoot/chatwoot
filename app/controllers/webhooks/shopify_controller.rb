class Webhooks::ShopifyController < ActionController::API
  before_action :verify_hmac!

  def events
    case request.headers['X-Shopify-Topic']
    when 'shop/redact'
      handle_shop_redact
    end

    head :ok
  end

  private

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

    Integrations::Hook.where(app_id: 'shopify', reference_id: shop_domain).destroy_all
  end
end
