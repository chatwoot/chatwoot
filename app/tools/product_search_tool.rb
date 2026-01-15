# frozen_string_literal: true

# Tool for searching products in the account's catalog
# Used by AI agent to find products for customers
#
# Example usage in agent:
#   chat.with_tools([ProductSearchTool])
#   response = chat.ask("Find products related to coffee")
#
class ProductSearchTool < BaseTool
  description 'Search products in the catalog by name or description. ' \
              'Use this when customers ask about products, prices, or what items are available. ' \
              'Returns product details including ID, name, description, and price.'

  param :query, type: :string, desc: 'Search term to find products (searches titles and descriptions)', required: true
  param :max_results, type: :integer, desc: 'Maximum number of products to return (default: 5, max: 10)', required: false

  def execute(query:, max_results: 5)
    validate_context!

    max_results = [[max_results.to_i, 1].max, 10].min # Clamp between 1 and 10

    products = search_products(query, max_results)

    if products.empty?
      log_execution({ query: query }, { found: 0 })
      return success_response({
                                products: [],
                                message: "No products found matching '#{query}'",
                                query: query
                              })
    end

    result = format_products(products)
    log_execution({ query: query, max_results: max_results }, { found: products.size })

    success_response(result)
  rescue StandardError => e
    log_execution({ query: query }, {}, success: false, error_message: e.message)
    error_response("Failed to search products: #{e.message}")
  end

  private

  def search_products(query, limit)
    search_term = "%#{query.downcase}%"

    current_account.products
                   .where(
                     'LOWER(title_en) LIKE :term OR LOWER(title_ar) LIKE :term OR ' \
                     'LOWER(description_en) LIKE :term OR LOWER(description_ar) LIKE :term',
                     term: search_term
                   )
                   .limit(limit)
  end

  def format_products(products)
    currency = current_account.catalog_settings&.currency || 'SAR'

    {
      products: products.map do |product|
        {
          id: product.id,
          title_en: product.title_en,
          title_ar: product.title_ar,
          description_en: product.description_en.to_s.truncate(200),
          description_ar: product.description_ar.to_s.truncate(200),
          price: product.price.to_f,
          currency: currency
        }
      end,
      count: products.size,
      currency: currency
    }
  end
end
