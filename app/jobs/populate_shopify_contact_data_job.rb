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
    id, email, phone_number = params.values_at(:id, :email, :phone_number)

    customers = fetch_customers(email, phone_number)

    return if customers.empty?

    customer = customers.first
    Rails.logger.info("Populating shopify customer data #{customer['id']}")

    contact = Contact.find_by(id: id)
      contact.update(custom_attributes: contact.custom_attributes.merge({shopify_customer_id:customer['id'] , shopify_customer_email: customer['email'], shopify_customer_phone:customer['phone']}))
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
