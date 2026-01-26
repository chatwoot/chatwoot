# frozen_string_literal: true

# Provides product catalog support for conversation agents
module CatalogSupport
  extend ActiveSupport::Concern

  private

  def catalog_instructions
    return nil unless catalog_access_enabled?

    <<~PROMPT
      ## Product Catalog & Shopping

      #{build_products_list}

      When customers ask about products or want to buy something:
      1. *Recommend Products*: Use the product information above to suggest relevant items
      2. *Get Details*: Use the product_details tool when customers want more info
      3. *Create Cart*: Use create_cart tool with product IDs and quantities
      4. *Payment Link*: After creating a cart, a payment link is automatically sent

      *Handling Follow-up References:*
      When a customer says "it", "this one", "that product", or "add to cart" without specifying:
      - Look at your previous messages in the conversation history
      - Find the product ID you mentioned most recently
      - Use that product ID for the cart or follow-up action
      - Do NOT ask "which product?" if you already discussed one
    PROMPT
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
      lines << "- #{title} (ID: #{product.id}) - #{price} #{currency}"
    end

    lines.join("\n")
  end
end
