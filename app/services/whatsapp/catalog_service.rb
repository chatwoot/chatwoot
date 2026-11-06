class Whatsapp::CatalogService
  PRODUCT_FIELDS = 'retailer_id,name,description,price,image_url,additional_image_urls,url,product_sets{id,name}'.freeze
  PAGE_SIZE = 100
  CACHE_TTL = 15.minutes
  CATALOG_ID_CACHE_TTL = 24.hours
  DEFAULT_COLLECTION_NAME = 'all products'.freeze
  PERMISSION_ERROR_CODE = 200

  class ApiError < StandardError
    attr_reader :permission

    def initialize(message, permission: false)
      super(message)
      @permission = permission
    end
  end

  pattr_initialize [:channel!, :refresh]

  def perform
    with_catalog do |catalog_id|
      { status: 'ok', catalog_id: catalog_id, collections: collections(catalog_id) }
    end
  end

  # Reads a single page of products, from the catalog or from one of its collections.
  def products(limit:, after: nil, query: nil, collection_id: nil)
    with_catalog do |catalog_id|
      next { status: 'invalid_collection' } unless known_collection?(catalog_id, collection_id)

      page = -> { products_page(collection_id || catalog_id, limit, after, query) }
      next page.call if after.present? || query.present?

      Rails.cache.fetch("whatsapp_catalog_products/#{channel.id}/#{catalog_id}/#{collection_id || 'all'}/#{limit}",
                        expires_in: CACHE_TTL, force: refresh?) { page.call }
    end
  end

  private

  def with_catalog
    catalog_id = resolve_catalog_id
    return { status: 'no_catalog' } if catalog_id.blank?

    yield catalog_id
  rescue ApiError => e
    Rails.logger.warn "[WHATSAPP CATALOG] channel=#{channel.id} #{e.message}"
    { status: e.permission ? 'missing_permission' : 'error' }
  rescue StandardError => e
    Rails.logger.warn "[WHATSAPP CATALOG] channel=#{channel.id} #{e.class}: #{e.message}"
    { status: 'error' }
  end

  def refresh?
    %w[1 true].include?(refresh.to_s)
  end

  def resolve_catalog_id
    channel.provider_config['catalog_id'].presence ||
      Rails.cache.fetch("whatsapp_catalog_id/#{channel.id}", expires_in: CATALOG_ID_CACHE_TTL, force: refresh?, skip_nil: true) do
        request("#{channel.provider_config['business_account_id']}/product_catalogs", limit: PAGE_SIZE)['data']&.first&.dig('id')
      end
  end

  def known_collection?(catalog_id, collection_id)
    collection_id.nil? || collections(catalog_id).pluck(:id).include?(collection_id)
  end

  def collections(catalog_id)
    Rails.cache.fetch("whatsapp_catalog_collections/#{channel.id}/#{catalog_id}", expires_in: CACHE_TTL, force: refresh?) do
      sets = product_sets(catalog_id)
      sets.reject { |set| default_collection?(set) }.map { |set| { id: set['id'], name: set['name'], count: set['product_count'] } }
    end
  end

  # Meta pages this edge too, so every page is followed until it reports no next cursor.
  def product_sets(catalog_id)
    sets = []
    after = nil
    loop do
      body = request("#{catalog_id}/product_sets", { fields: 'id,name,product_count', limit: PAGE_SIZE, after: after }.compact)
      sets.concat(body['data'].to_a)
      after = body.dig('paging', 'next').present? ? body.dig('paging', 'cursors', 'after').presence : nil
      return sets if after.blank?
    end
  end

  def default_collection?(set)
    set['name'].to_s.casecmp?(DEFAULT_COLLECTION_NAME)
  end

  def products_page(parent_id, limit, after, text)
    params = { fields: PRODUCT_FIELDS, limit: limit, after: after.presence }
    params[:filter] = { name: { i_contains: text } }.to_json if text.present?
    body = request("#{parent_id}/products", params.compact)
    page = body['data'].to_a
    cursor = body.dig('paging', 'cursors', 'after').presence if body.dig('paging', 'next').present?
    { status: 'ok', products: page.map { |product| format_product(product) }, next_cursor: cursor }
  end

  def format_product(product)
    {
      retailer_id: product['retailer_id'],
      name: product['name'],
      price: product['price'],
      image_urls: [product['image_url'], *product['additional_image_urls']].compact,
      description: product['description'],
      url: product['url'],
      collection_ids: product.dig('product_sets', 'data').to_a.reject { |set| default_collection?(set) }.pluck('id')
    }
  end

  def request(path, query)
    response = HTTParty.get("#{base_url}/#{path}", query: query, headers: { 'Authorization' => "Bearer #{channel.provider_config['api_key']}" })
    body = response.parsed_response
    return body if response.success?

    error = body.is_a?(Hash) ? body['error'] || {} : {}
    permission = error['code'] == PERMISSION_ERROR_CODE || error['message'].to_s.match?(/permission/i)
    raise ApiError.new("HTTP #{response.code} code=#{error['code']} #{error['message']}", permission: permission)
  end

  def base_url
    "#{ENV.fetch('WHATSAPP_CLOUD_BASE_URL', 'https://graph.facebook.com')}/#{GlobalConfigService.load('WHATSAPP_API_VERSION', 'v22.0')}"
  end
end
