class Integrations::Shopify::ProductsService
  REQUIRED_SCOPE = 'read_products'.freeze
  MAX_LIMIT = 10
  FALLBACK_MULTIPLIER = 5
  MAX_FALLBACK_LIMIT = 50

  def initialize(account:)
    @account = account
    @client_service = Integrations::Shopify::ClientService.new(account: account)
  end

  # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
  def search_products(query:, limit: MAX_LIMIT)
    Rails.logger.info(
      "[Integrations::Shopify::ProductsService] search_products account_id=#{@account.id} " \
      "query=#{query.inspect} limit=#{limit}"
    )
    return no_products_result(query) if query.blank?

    client_result = @client_service.fetch_client
    return client_result unless client_result[:ok]

    unless product_scope_granted?
      Rails.logger.warn(
        "[Integrations::Shopify::ProductsService] missing_scope account_id=#{@account.id} " \
        "required=#{REQUIRED_SCOPE} granted=#{@client_service.granted_scopes.join(',')}"
      )
      return failure(:insufficient_scope, 'Shopify integration is missing read_products scope.')
    end

    products = fetch_products(client_result[:data][:client], query, normalized_limit(limit))
    Rails.logger.info(
      "[Integrations::Shopify::ProductsService] shopify_response account_id=#{@account.id} " \
      "query=#{query.inspect} products_count=#{products.length}"
    )

    return no_products_result(query) if products.empty?

    success(
      products: products.map { |product| normalize_product(product, client_result[:data][:hook].reference_id) }
    )
  rescue ShopifyAPI::Errors::HttpResponseError => e
    Rails.logger.error("[Integrations::Shopify::ProductsService] Shopify error: #{e.message}")
    failure(:provider_error, 'Shopify product search failed.')
  rescue StandardError => e
    Rails.logger.error("[Integrations::Shopify::ProductsService] #{e.class}: #{e.message}")
    failure(:provider_error, 'Shopify product search failed.')
  end
  # rubocop:enable Metrics/AbcSize, Metrics/MethodLength

  private

  def product_scope_granted?
    @client_service.scopes_include?(REQUIRED_SCOPE)
  end

  def no_products_result(query)
    Rails.logger.info(
      "[Integrations::Shopify::ProductsService] no_results account_id=#{@account.id} query=#{query.inspect}"
    )
    failure(:no_results, 'No products found for the provided query.')
  end

  def fetch_products(client, query, limit)
    products = fetch_products_by_title(client, query, limit)
    return products if products.any?

    fallback_limit = [(limit * FALLBACK_MULTIPLIER), MAX_FALLBACK_LIMIT].min
    Rails.logger.info(
      "[Integrations::Shopify::ProductsService] fallback_keyword_search account_id=#{@account.id} " \
      "query=#{query.inspect} fallback_limit=#{fallback_limit}"
    )

    fallback_products = fetch_active_products(client, fallback_limit)
    filter_products_by_keyword(fallback_products, query).first(limit)
  end

  def fetch_products_by_title(client, query, limit)
    response = client.get(
      path: 'products.json',
      query: product_query(limit: limit, title: query)
    )
    response.body['products'] || []
  end

  def fetch_active_products(client, limit)
    response = client.get(
      path: 'products.json',
      query: product_query(limit: limit)
    )
    response.body['products'] || []
  end

  def product_query(limit:, title: nil)
    {
      title: title,
      status: 'active',
      limit: limit,
      fields: 'id,title,vendor,product_type,handle,variants'
    }.compact
  end

  def filter_products_by_keyword(products, query)
    keyword = query.to_s.downcase.strip
    return [] if keyword.blank?

    products.select do |product|
      searchable_text = [product['title'], product['vendor'], product['product_type']].compact.join(' ').downcase
      searchable_text.include?(keyword)
    end
  end

  def normalize_product(product, shop_domain)
    variants = Array(product['variants'])
    first_variant = variants.first || {}

    {
      id: product['id'],
      title: product['title'],
      vendor: product['vendor'],
      product_type: product['product_type'],
      handle: product['handle'],
      storefront_url: storefront_url(shop_domain, product['handle']),
      price: first_variant['price'],
      availability: availability_summary(variants)
    }
  end

  def storefront_url(shop_domain, handle)
    return nil if shop_domain.blank? || handle.blank?

    "https://#{shop_domain}/products/#{handle}"
  end

  def availability_summary(variants)
    return 'Out of stock' if variants.empty?

    available_count = variants.count { |variant| variant_available?(variant) }
    return 'Out of stock' if available_count.zero?
    return 'In stock' if available_count == variants.size

    "Partially in stock (#{available_count}/#{variants.size} variants)"
  end

  def variant_available?(variant)
    return variant['available'] if [true, false].include?(variant['available'])

    quantity = variant['inventory_quantity']
    return quantity.to_i.positive? unless quantity.nil?

    variant['inventory_policy'] == 'continue'
  end

  def normalized_limit(limit)
    value = limit.to_i
    return MAX_LIMIT if value <= 0

    [value, MAX_LIMIT].min
  end

  def success(data)
    { ok: true, data: data }
  end

  def failure(code, message)
    { ok: false, error: { code: code, message: message } }
  end
end
