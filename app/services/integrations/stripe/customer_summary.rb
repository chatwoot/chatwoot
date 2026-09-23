class Integrations::Stripe::CustomerSummary
  RECENT_LIMIT = 5

  def initialize(connection:, contact:)
    @connection = connection
    @contact = contact
  end

  def perform(customer_id: nil)
    return { customers: [], missing_email: true } if @contact.email.blank?

    @options = { api_key: @connection.api_token }
    @products = {}
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
      subscriptions: subscriptions.data.map { |subscription| subscription_details(subscription.to_hash) },
      invoices: invoices.data.map { |invoice| invoice.to_hash.slice(:id, :number, :status, :total, :currency, :created) }
    }
  end

  def subscription_details(subscription)
    subscription.slice(:id, :status, :trial_end, :cancel_at, :cancel_at_period_end, :canceled_at).merge(
      items: subscription.fetch(:items, {}).fetch(:data, []).map { |item| subscription_item(item, subscription) },
      has_more_items: subscription.dig(:items, :has_more) || false
    )
  end

  def subscription_item(item, subscription)
    price = item.fetch(:price)
    {
      id: item[:id], name: product_name(price[:product]) || price[:nickname], quantity: item[:quantity],
      unit_amount: price[:unit_amount_decimal] || price[:unit_amount], currency: price[:currency],
      recurring: price.fetch(:recurring).slice(:interval, :interval_count, :usage_type),
      billing_scheme: price[:billing_scheme],
      current_period_start: item[:current_period_start] || subscription[:current_period_start],
      current_period_end: item[:current_period_end] || subscription[:current_period_end]
    }
  end

  def product_name(product_id)
    return @products[product_id] if @products.key?(product_id)

    @products[product_id] = ::Stripe::Product.retrieve(product_id, @options).to_hash[:name]
  rescue ::Stripe::PermissionError
    # Existing installations may not yet have granted product_read.
    @products[product_id] = nil
  end
end
