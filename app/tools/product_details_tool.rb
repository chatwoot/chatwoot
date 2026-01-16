# frozen_string_literal: true

# Tool for getting full details of a specific product by ID
# Used by AI agent when customer asks about a specific product
#
# Example usage in agent:
#   chat.with_tools([ProductDetailsTool])
#   response = chat.ask("Get details for product 123")
#
class ProductDetailsTool < BaseTool
  description 'Get full details about a specific product by its ID. ' \
              'Use this when you need complete information about a product ' \
              'including title, description, price, and image.'

  param :product_id, type: :integer, desc: 'The ID of the product to retrieve', required: true

  def execute(product_id:)
    validate_context!

    product = find_product(product_id)

    unless product
      log_execution({ product_id: product_id }, { found: false })
      return error_response("Product with ID #{product_id} not found")
    end

    result = format_product_details(product)
    log_execution({ product_id: product_id }, { found: true })

    success_response(result)
  rescue StandardError => e
    log_execution({ product_id: product_id }, {}, success: false, error_message: e.message)
    error_response("Failed to get product details: #{e.message}")
  end

  private

  def find_product(product_id)
    current_account.products.find_by(id: product_id)
  end

  def format_product_details(product)
    currency = current_account.catalog_settings&.currency || 'SAR'

    {
      product: {
        id: product.id,
        title_en: product.title_en,
        title_ar: product.title_ar,
        description_en: product.description_en,
        description_ar: product.description_ar,
        price: product.price.to_f,
        currency: currency,
        image_url: "#{ENV.fetch('FRONTEND_URL', nil)}#{product.image_url}"
      }
    }
  end
end
