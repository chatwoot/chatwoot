class PaymentLinks::FilterService < FilterService
  include Filters::FilterHelper

  ATTRIBUTE_MODEL = 'payment_link_attribute'.freeze

  def initialize(account, user, params)
    @account = account
    super(params, user)
  end

  def perform
    validate_query_operator
    @payment_links = query_builder(@filters['payment_links'])

    {
      payment_links: @payment_links,
      count: @payment_links.count
    }
  end

  def filter_values(query_hash)
    current_val = query_hash['values'][0]
    if query_hash['attribute_key'] == 'status'
      payment_link_status_values(query_hash['values'])
    elsif current_val.is_a?(String)
      current_val.downcase
    else
      current_val
    end
  end

  def base_relation
    @account.payment_links
  end

  def filter_config
    {
      entity: 'PaymentLink',
      table_name: 'payment_links'
    }
  end

  private

  def payment_link_status_values(values)
    values.map do |value|
      PaymentLink.statuses[value.to_sym]
    end
  end
end
