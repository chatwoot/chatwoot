# frozen_string_literal: true

# Provides product catalog support for conversation agents
module CatalogSupport
  extend ActiveSupport::Concern

  private

  def catalog_instructions
    return nil unless catalog_access_enabled?

    <<~PROMPT
      #{section_header('PRODUCT CATALOG & SHOPPING')}

      #{build_products_list}

      Rules:

      1. Recommend relevant products when appropriate
      2. Use product_details tool for detailed inquiries
      3. Use create_cart tool with product IDs and quantities
      4. After cart creation, you will receive a payment_url — you MUST include this link in your reply to the customer
      5. Use send_storefront_link tool when the customer wants to browse products themselves or asks for a shopping link
      6. After generating a storefront link, you will receive a storefront_url — you MUST include this link in your reply to the customer

      Handling follow-ups:

      * If the user says "this", "it", or "that product", refer to the MOST RECENTLY mentioned product
      * Do NOT ask which product if context already exists
    PROMPT
  end

  def catalog_tools
    return [] unless catalog_access_enabled?

    [ProductDetailsTool, CreateCartTool, SendStorefrontLinkTool]
  end

  def catalog_enabled?
    current_account&.catalog_settings&.enabled?
  end

  def catalog_access_enabled?
    catalog_enabled? && current_assistant&.feature_catalog_access_enabled?
  end

  def build_products_list
    products = current_account.products.limit(30)
    return 'No products available in the catalog yet.' if products.empty?

    currency = current_account.catalog_settings&.currency || 'SAR'

    lines = ["Available Products (#{currency}):"]
    products.each do |product|
      title = product.title_en.presence || product.title_ar
      price = format('%.2f', product.price)
      stock_info = product.stock.nil? ? 'In Stock' : "#{product.stock} left"
      lines << "- #{title} (ID: #{product.id}) - #{price} #{currency} [#{stock_info}]"
    end

    lines.join("\n")
  end
end
