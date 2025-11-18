module Integrations::Ecommerce
  class WoocommerceProvider < BaseProvider
    def list_products(page: 1, per_page: 20, search: nil)
      client = Integrations::Woocommerce::Client.new(@hook)
      result = client.list_products(page: page, per_page: per_page, search: search)

      {
        products: result[:products].map { |p| normalize_product(p, 'woocommerce') },
        pagination: result[:pagination],
        provider: 'woocommerce'
      }
    end

    def get_product(product_id)
      client = Integrations::Woocommerce::Client.new(@hook)
      product = client.get_product(product_id)
      normalize_product(product, 'woocommerce')
    end
  end
end
