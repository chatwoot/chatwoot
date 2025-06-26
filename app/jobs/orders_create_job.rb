class OrdersCreateJob < ActiveJob::Base
  extend ShopifyAPI::Webhooks::Handler

  class << self
    def handle(topic:, shop:, body:)
      perform_later(topic: topic, shop_domain: shop, webhook: body)
    end
  end

  def perform(topic:, shop_domain:, webhook:)
    shop = Shop.find_by(shopify_domain: shop_domain)
    hook = Integrations::Hook.find_by(reference_id: shop_domain)
    account_id = hook.account_id
    account = Account.find(account_id)

    if shop.nil?
      logger.error("#{self.class} failed: cannot find shop with domain '#{shop_domain}'")

      raise ActiveRecord::RecordNotFound, "Shop Not Found"
    end

    shop.with_shopify_session do |session|
      account.orders.upsert(
        {
          id:                 webhook['id'],
          billing_address:    webhook['billing_address'],
          cancel_reason:      webhook['cancel_reason'],
          cancelled_at:       webhook['cancelled_at'],
          currency:           webhook['currency'],
          financial_status:    webhook['financial_status'],
          fulfillment_status:  webhook['fulfillment_status'],
          line_items:         webhook['line_items'],
          name:               webhook['name'],
          note:               webhook['note'],
          order_status_url:   webhook['order_status_url'],
          refunds:            webhook['refunds'],
          shipping_address:   webhook['shipping_address'],
          shipping_lines:     webhook['shipping_lines'],
          subtotal_price:     webhook['subtotal_price'],
          tags:               webhook['tags'],
          total_price:        webhook['total_price'],
          total_tax:          webhook['total_tax'],
          customer_id:        webhook['customer']['id']
        },
        unique_by: :id
      )
    end
  end
end
