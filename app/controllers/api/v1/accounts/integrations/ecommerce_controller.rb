class Api::V1::Accounts::Integrations::EcommerceController < Api::V1::Accounts::BaseController
  before_action :find_active_integration

  def products
    provider = provider_for_integration(@integration)
    result = provider.list_products(
      page: params[:page] || 1,
      per_page: params[:per_page] || 20,
      search: params[:search]
    )

    render json: result
  rescue StandardError => e
    Rails.logger.error("Ecommerce products error: #{e.message}")
    render json: { error: e.message, products: [] }, status: :unprocessable_entity
  end

  def send_product
    provider = provider_for_integration(@integration)
    product = provider.get_product(params[:product_id])
    
    conversation = Current.account.conversations.find(params[:conversation_id])
    product_url = product[:product_url]
    
    # Create a message with the product link
    message_params = {
      content: product_url,
      message_type: :outgoing,
      private: false,
      sender: current_user
    }
    
    Messages::MessageBuilder.new(current_user, conversation, message_params).perform

    render json: { success: true }
  rescue StandardError => e
    Rails.logger.error("Send product error: #{e.message}")
    render json: { error: e.message }, status: :unprocessable_entity
  end

  private

  def find_active_integration
    # Check for WooCommerce integration first, then Shopify
    @integration = Current.account.hooks.find_by(app_id: 'woocommerce', status: 'enabled') ||
                   Current.account.hooks.find_by(app_id: 'shopify', status: 'enabled')

    return if @integration.present?

    render json: { error: 'No active e-commerce integration found', products: [] }, status: :not_found
  end

  def provider_for_integration(integration)
    case integration.app_id
    when 'woocommerce'
      Integrations::Ecommerce::WoocommerceProvider.new(integration)
    when 'shopify'
      Integrations::Ecommerce::ShopifyProvider.new(integration)
    else
      raise "Unsupported e-commerce provider: #{integration.app_id}"
    end
  end
end
