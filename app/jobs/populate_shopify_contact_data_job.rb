class PopulateShopifyContactDataJob < ApplicationJob
  queue_as :default

  def perform(params)
    begin
      setup_shopify_context(params[:account_id])
      populate(params)
    rescue StandardError => e
      Rails.logger.error "Exception: #{e.class} - #{e.message}"
    end
  end

  def populate(params)
    account_id, id, email, phone_number = params.values_at(:account_id, :id, :email, :phone_number)

    customers = fetch_customers(email, phone_number)

    return if customers.empty?

    customer = customers.first
    Rails.logger.info("Populating shopify account: #{account_id} and customer data #{customer['id']}")

    contact = Contact.find_by(id: id)

    old_shopify_customer_id = contact.custom_attributes['shopify_customer_id']

    contact.update(custom_attributes: contact.custom_attributes.merge({shopify_customer_id:customer['id'] , shopify_customer_email: customer['email'], shopify_customer_phone:customer['phone']}))

    contact.save!

    # Update customer orders
    if old_shopify_customer_id != customer['id']
      contact.update(custom_attributes: contact.custom_attributes.merge({ shopify_orders_populated: false}))
      update_customer_orders(account_id, customer['id'])
    end

    contact.update(custom_attributes: contact.custom_attributes.merge({ shopify_orders_populated: true}))
  end

  def update_customer_orders(account_id, customer_id)
    orders = fetch_orders(account_id, customer_id)
    account = Account.find(account_id)

    orders.each do |shopify_order|
      Rails.logger.info("Added order: #{shopify_order}")
      account.orders.upsert(
        {
          id:                 shopify_order['id'],
          billing_address:    shopify_order['billing_address'],
          cancel_reason:      shopify_order['cancel_reason'],
          cancelled_at:       shopify_order['cancelled_at'],
          currency:           shopify_order['currency'],
          financial_status:    shopify_order['financial_status'],
          fulfillment_status:  shopify_order['fulfillment_status'],
          line_items:         shopify_order['line_items'],
          name:               shopify_order['name'],
          note:               shopify_order['note'],
          order_status_url:   shopify_order['order_status_url'],
          refunds:            shopify_order['refunds'],
          shipping_address:   shopify_order['shipping_address'],
          shipping_lines:     shopify_order['shipping_lines'],
          subtotal_price:     shopify_order['subtotal_price'],
          tags:               shopify_order['tags'],
          total_price:        shopify_order['total_price'],
          total_tax:          shopify_order['total_tax'],
          customer_id:        customer_id
        },
        unique_by: :id
      )
    end
  end

  def fetch_customers(email, phone_number)
    query = []
    query << "email:#{email}" if email.present?
    query << "phone:#{phone_number}" if phone_number.present?

    shopify_client.get(
      path: 'customers/search.json',
      query: {
        query: query.join(' OR '),
        fields: 'id,email,phone'
      }
    ).body['customers'] || []
  end

  def fetch_orders(account_id, customer_id)
    orders = shopify_client.get(
      path: 'orders.json',
      query: {
        customer_id: customer_id,
        status: 'any'
        # fields: 'id,email,created_at,total_price,currency,fulfillment_status,financial_status' // REVIEW: fetching all fields from now, but only a subset is being saved, maybe we can optimize the query
      }
    ).body['orders'] || []

    @hook = Integrations::Hook.find_by!(account: account_id, app_id: 'shopify')

    orders.map do |order|
      order.merge('admin_url' => "https://#{@hook.reference_id}/admin/orders/#{order['id']}")
    end
  end


  def setup_shopify_context(account_id)
    @shopify_service =  Shopify::ClientService.new(account_id)
  end

  def shopify_session
    @shopify_service.shopify_sesion
  end

  def shopify_client
    @shopify_service.shopify_client
  end
end
