require 'net/http'
require 'uri'
require 'json'

module Integrations::Woocommerce
  class Client
    def initialize(hook)
      @hook = hook
      @settings = hook.settings.with_indifferent_access
      @store_base_url = normalize_url(@settings[:store_base_url])
      @consumer_key = @settings[:consumer_key]
      @consumer_secret = @settings[:consumer_secret]
      @api_version = @settings[:api_version].presence || 'v3'
    end

    def test_connection
      response = get('products', per_page: 1)
      { success: true, data: response }
    rescue StandardError => e
      { success: false, error: error_message(e) }
    end

    def list_products(page: 1, per_page: 20, search: nil, category: nil)
      params = {
        page: page,
        per_page: [per_page, 100].min,
        _fields: 'id,name,price,regular_price,stock_status,stock_quantity,images,permalink,sku'
      }
      params[:search] = search if search.present?
      params[:category] = category if category.present?

      response = get('products', params)
      {
        products: response,
        pagination: extract_pagination_data
      }
    end

    def get_product(product_id)
      get("products/#{product_id}")
    end

    private

    def get(endpoint, params = {})
      uri = build_uri(endpoint, params)
      request = Net::HTTP::Get.new(uri)
      request.basic_auth(@consumer_key, @consumer_secret)

      response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.scheme == 'https', open_timeout: 10, read_timeout: 10) do |http|
        http.request(request)
      end

      handle_response(response)
    end

    def build_uri(endpoint, params = {})
      base = "#{@store_base_url}/wp-json/wc/#{@api_version}/#{endpoint}"
      uri = URI(base)
      uri.query = URI.encode_www_form(params) unless params.empty?
      uri
    end

    def handle_response(response)
      @last_response = response

      case response.code.to_i
      when 200, 201
        JSON.parse(response.body)
      when 401, 403
        raise Integrations::Woocommerce::AuthenticationError, 'Invalid credentials or insufficient permissions'
      when 404
        raise Integrations::Woocommerce::NotFoundError, 'API endpoint not found. Check if WooCommerce is installed and permalinks are enabled'
      else
        raise Integrations::Woocommerce::ApiError, "API returned status #{response.code}: #{response.body}"
      end
    end

    def extract_pagination_data
      return {} unless @last_response

      {
        total: @last_response['x-wp-total']&.to_i || 0,
        total_pages: @last_response['x-wp-totalpages']&.to_i || 1,
        current_page: 1
      }
    end

    def normalize_url(url)
      return '' if url.blank?

      url.strip.gsub(%r{/+$}, '')
    end

    def error_message(error)
      case error
      when Integrations::Woocommerce::AuthenticationError
        'Authentication failed. Please check your Consumer Key and Consumer Secret.'
      when Integrations::Woocommerce::NotFoundError
        'WooCommerce API not found. Make sure WooCommerce is installed and "Pretty Permalinks" are enabled in WordPress.'
      when Net::OpenTimeout, Net::ReadTimeout
        'Connection timeout. Please check your store URL.'
      else
        "Connection failed: #{error.message}"
      end
    end
  end
end
