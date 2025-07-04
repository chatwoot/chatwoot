# frozen_string_literal: true

class Webhooks::ShopifyController < ActionController::API
  # This controller handles webhooks and doesn't need standard Rails authentication

  # HMAC verification enabled for production
  before_action :verify_shopify_webhook

  # POST /webhooks/shopify/compliance
  def compliance
    topic = request.headers['HTTP_X_SHOPIFY_TOPIC']
    shop_domain = request.headers['HTTP_X_SHOPIFY_SHOP_DOMAIN']
    webhook_payload = params.to_unsafe_h

    Rails.logger.info "Received Shopify compliance webhook. Topic: #{topic}, Shop: #{shop_domain}"

    # Log the webhook payload for audit purposes
    Rails.logger.info "Shopify compliance webhook payload: #{webhook_payload.inspect}"

    # For now, we are just acknowledging the request with a 200 OK.
    # No data is being redacted, as per legal requirements to retain data.
    # For data requests, a system to notify the store owner should be implemented later.
    head :ok
  end

  private

  def verify_shopify_webhook
    webhook_secret = GlobalConfigService.load('SHOPIFY_CLIENT_SECRET', nil)

    if webhook_secret.blank?
      Rails.logger.error 'SHOPIFY_CLIENT_SECRET not configured'
      render json: { error: 'Webhook secret not configured' }, status: :internal_server_error
      return
    end

    payload = request.body.read
    signature = request.headers['HTTP_X_SHOPIFY_HMAC_SHA256']

    if signature.blank?
      Rails.logger.error 'Missing Shopify HMAC signature'
      render json: { error: 'Missing signature' }, status: :unauthorized
      return
    end

    # Verify HMAC signature
    unless verify_hmac(payload, signature, webhook_secret)
      Rails.logger.error 'Shopify webhook HMAC verification failed'
      render json: { error: 'Invalid signature' }, status: :unauthorized
      return
    end

    # Reset the request body for controller action
    request.body.rewind
  end

  def verify_hmac(payload, signature, secret)
    calculated_hmac = Base64.strict_encode64(OpenSSL::HMAC.digest('sha256', secret, payload))
    Rack::Utils.secure_compare(calculated_hmac, signature)
  rescue StandardError => e
    Rails.logger.error "Error verifying Shopify HMAC: #{e.message}"
    false
  end
end