class Shopify::PopulateStoreLocationsJob < ApplicationJob
  queue_as :default

LOCATIONS_QUERY = <<~GRAPHQL
  query {
    locations(first: 10) {
      nodes {
        id
        name
        shipsInventory
        fulfillsOnlineOrders
        createdAt
        updatedAt
        isActive
        address {
          address1
          address2
          city
          province
          provinceCode
          country
          countryCode
          zip
          latitude
          longitude
        }
      }
    }
  }
GRAPHQL

  def perform(params)
    get_locations(params)
  end

  def get_locations(params)
    shop_domain, account_id = params.values_at(:shop_domain, :account_id)

    shop = Shop.find_by(shopify_domain: shop_domain)
    account = Account.find_by(id: account_id)

    shop.with_shopify_session do
        response = ShopifyGraphql.execute(
          LOCATIONS_QUERY
        )

        data = response.data

        locations = data.locations.nodes
        Rails.logger.info("Got locations: #{locations}")

        locations.each do |elem|
          location_id = (elem.id.split('/').last);
          account.shopify_locations.create!(
            id: location_id,
            name: elem.name,
            ships_inventory: elem.shipsInventory,
            fulfills_online_orders: elem.fulfillsOnlineOrders,
            created_at: elem.createdAt,
            updated_at: elem.updatedAt,
            is_active: elem.isActive,
            address: elem.address
          )
        end
    end

  end
end
