class Integrations::FilterService < FilterService
  ATTRIBUTE_MODEL = 'order_attribute'.freeze

  def initialize(account, user, params)
    @account = account
    super(params, user)
  end

  def perform
    @orders = query_builder(@filters['orders'])

    {
      orders: @orders,
      count: @orders.count
    }
  end

  def filter_values(query_hash)
    current_val = query_hash['values'][0]
    case query_hash['attribute_key']
    when 'order_number', 'platform', 'created_via', 'status', 'payment_status', 'date_created', 'date_modified'
      current_val.downcase
    when 'contact_name'
      "%#{current_val.downcase}%"
    else
      current_val
    end
  end

  def base_relation
    @account.orders
  end

  def filter_config
    {
      entity: 'Order',
      table_name: 'orders'
    }
  end

  private

  def equals_to_filter_string(filter_operator, current_index)
    return "= :value_#{current_index}" if filter_operator == 'equal_to'

    "!= :value_#{current_index}"
  end
end
