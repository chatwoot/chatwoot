class Integrations::Stripe::CustomerSummary
  RECENT_LIMIT = 5

  def initialize(connection:, contact:)
    @connection = connection
    @contact = contact
  end

  def perform(customer_id: nil)
    return { customers: [], missing_email: true } if @contact.email.blank?

    @options = { api_key: @connection.api_token }
    customers = ::Stripe::Customer.search({ query: "email:#{@contact.email.to_json}", limit: 100 }, @options)
    matches = customers.data.select { |customer| customer.email&.casecmp?(@contact.email) }
                       .map { |customer| customer.to_hash.slice(:id, :name, :email, :phone) }
    selected = select_customer(matches, customer_id)
    result = { customers: matches, has_more_customers: customers.has_more }
    selected ? result.merge(customer: selected, **billing_details(selected[:id])) : result
  end

  private

  def select_customer(matches, customer_id)
    selected = matches.find { |customer| customer[:id] == customer_id } if customer_id
    raise ActiveRecord::RecordNotFound if customer_id && !selected

    selected || (matches.first if matches.one?)
  end

  def billing_details(customer_id)
    subscriptions = ::Stripe::Subscription.list({ customer: customer_id, status: 'all', limit: RECENT_LIMIT }, @options)
    invoices = ::Stripe::Invoice.list({ customer: customer_id, limit: RECENT_LIMIT }, @options)
    {
      subscriptions: subscriptions.data.map { |subscription| subscription.to_hash.slice(:id, :status) },
      invoices: invoices.data.map { |invoice| invoice.to_hash.slice(:id, :number, :status, :total, :currency, :created) }
    }
  end
end
