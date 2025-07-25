require 'httparty'

class ChatscommerceService::StoreService
  include HTTParty

  class StoreError < StandardError; end

  def initialize
    self.class.base_uri chatscommerce_api_url
    self.class.headers({
                         'Content-Type' => 'application/json',
                         'Authorization' => 'application/json'
                       })
  end

  def create_store(account, user_email)
    store_data = build_store_data(account, user_email)

    response = self.class.put(
      "#{chatscommerce_api_url}/api/stores/",
      body: { store: store_data }.to_json,
      headers: self.class.headers
    )
    handle_response(response)

    response.parsed_response
  end

  private

  def handle_response(response)
    raise StoreError, "Bad Request, url: #{response.request.last_uri}" if response.code == 404
    raise StoreError, "Error creating store: #{response.code}-#{response.body}" if response.code == 400
    raise StoreError, "Unexpected error: #{response.code}-#{response.body}" unless response.success?
  end

  def build_store_data(account, user_email)
    {
      id: account.custom_attributes['store_id'],
      name: account.name,
      email: user_email,
      phone: '',
      useCases: "#{account.name}UseCases",
      ecommercePlatform: 'shopify',
      isActive: true
    }
  end

  def chatscommerce_api_url
    Rails.application.config.chatscommerce_api_url ||
      ENV['AI_BACKEND_API'] ||
      Rails.application.credentials.chatscommerce_api_url
  end
end