class ShopifySyncJob < ApplicationJob
  queue_as :medium

  def perform
    integrations = Integrations::Shopify.all
    integrations.each do |item|
      sync_order(item)
    end
  end

  def sync_order(shopify_account)
    url = 'https://'+shopify_account.account_name+'/admin/api/2022-04/customers.json'
    
    response = RestClient.get(url, {
      "X-Shopify-Access-Token": shopify_account.access_token
    })
    response = JSON.parse(response)
    customers = response['customers']
    
    if customers.length > 0
      customers.each do |item|
        shopify_customer = Integrations::ShopifyCustomer.find_by(email: item['email'])
        if shopify_customer.nil?
          contact = Contact.new
          shopify_customer = Integrations::ShopifyCustomer.new
        else
          contact = Contact.find_by(email: item['email'])
          shopify_customer = Integrations::ShopifyCustomer.find_by(email: item['email'])
        end
        contact.email = item['email']
        contact.name = item['first_name'] + ' ' + item['last_name']
        contact.account_id = shopify_account.account_id
        contact.save!
        shopify_customer.email = item['email']
        shopify_customer.first_name = item['first_name']
        shopify_customer.last_name = item['last_name']
        shopify_customer.orders_count= item['orders_count']
        shopify_customer.account_id = shopify_account.account_id
        shopify_customer.customer_id = item['id']
        shopify_customer.contact_id = contact.id
        shopify_customer.shopify_account_id = shopify_account.id
        shopify_customer.save
      end
    end
  end
end
