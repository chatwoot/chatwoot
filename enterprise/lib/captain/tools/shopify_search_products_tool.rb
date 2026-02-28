class Captain::Tools::ShopifySearchProductsTool < Captain::Tools::ShopifyBaseTool
  description 'Search products in the connected Shopify store'
  param :query, type: 'string', desc: 'Search query for product name or keywords'

  def perform(_tool_context, query:)
    log_tool_usage('shopify_search_products_requested', { query: query })
    return eligibility_error_message if eligibility_error_message

    result = products_service.search_products(query: query, limit: 10)
    unless result[:ok]
      log_tool_usage('shopify_search_products_failed', { query: query, error: result[:error] })
      return format_domain_error(result[:error])
    end

    log_tool_usage('shopify_search_products_success', { query: query, products_count: result[:data][:products].length })

    format_products(result[:data][:products])
  rescue StandardError => e
    ChatwootExceptionTracker.new(e, account: @assistant.account).capture_exception
    'I could not fetch Shopify products right now. Please try again shortly.'
  end

  private

  def products_service
    @products_service ||= Integrations::Shopify::ProductsService.new(account: @assistant.account)
  end

  def format_products(products)
    lines = ["Found #{products.length} matching Shopify products:"]

    products.each_with_index do |product, index|
      lines << product_line(index, product)
    end

    lines.join("\n")
  end

  def product_line(index, product)
    [
      "#{index + 1}. #{product[:title]}",
      "Price: #{formatted_price(product[:price])}",
      "Availability: #{product[:availability]}",
      "URL: #{product[:storefront_url]}"
    ].join(' | ')
  end

  def formatted_price(price)
    return 'N/A' if price.blank?

    price.to_s
  end
end
