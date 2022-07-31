class ShopifySyncJob < ApplicationJob
  queue_as :medium

  def perform
    integrations = Integrations::Shopify.all
    integrations.each do |item|
      sync_order(item)
    end
  end

  def sync_order(shopify_account)
    url = 'https://'+shopify_account.account_name+'/admin/api/2022-04/orders.json?status=any'
    
    response = RestClient.get(url, {
      "X-Shopify-Access-Token": shopify_account.access_token
    })
    response = JSON.parse(response)
    cart = response['orders']
    
    if cart.length > 0
      cart.each do |item|
        if !item['customer'].nil? 
          shopify_customer = Integrations::ShopifyCustomer.find_by(email: item['customer']['email'])
          if shopify_customer.nil?
            contact = Contact.new
            contact.email = item['customer']['email']
            contact.name = item['customer']['first_name'] + ' ' + item['customer']['last_name']
            contact.account_id = shopify_account.account_id
            contact.save!

            shopify_customer = Integrations::ShopifyCustomer.new
            shopify_customer.email = item['customer']['email']
            shopify_customer.first_name = item['customer']['first_name']
            shopify_customer.last_name = item['customer']['last_name']
            shopify_customer.orders_count= item['customer']['orders_count']
            shopify_customer.account_id = shopify_account.account_id
            shopify_customer.contact_id = contact.id
            shopify_customer.save()
          end

          shopify_order = Integrations::ShopifyOrder.find_by(order_id: item['id'])
          if shopify_order.nil?
            shopify_order = Integrations::ShopifyOrder.new
            shopify_order.customer_id = shopify_customer.id
            shopify_order.order_id = item['id']
            shopify_order.cancelled_at = item['cancelled_at']
            shopify_order.closed_at = item['closed_at']
            shopify_order.currency = item['currency']
            shopify_order.current_total_price = item['current_total_price']
            shopify_order.order_number = item['order_number']
            shopify_order.order_status_url = item['order_status_url']
            shopify_order.order_created_at = item['created_at']
            shopify_order.account_id = shopify_account.account_id
            shopify_order.save!

            if !item['line_items'].nil?
              items = item['line_items']
              items.each do |single_item|
                shopify_order_item = Integrations::ShopifyOrderItem.new
                shopify_order_item.order_id = shopify_order.id
                shopify_order_item.name = single_item['name']
                shopify_order_item.price = single_item['price']
                shopify_order_item.quantity = single_item['quantity']
                shopify_order_item.save!
              end
            end
          end
        end
      end
    end
  end
end
