class Captain::Tools::ShopifyGetOrdersTool < Captain::Tools::ShopifyBaseTool
  description "Look up a customer's orders from Shopify"
  param :email, type: 'string', desc: 'Customer email used for order lookup', required: false
  param :phone_number, type: 'string', desc: 'Customer phone number used for order lookup', required: false

  # rubocop:disable Metrics/AbcSize
  def perform(tool_context, email: nil, phone_number: nil)
    log_tool_usage('shopify_get_orders_requested', { email_present: email.present?, phone_present: phone_number.present? })
    return eligibility_error_message if eligibility_error_message

    identity = resolve_contact_identity(tool_context&.state, { email: email, phone_number: phone_number })
    log_tool_usage(
      'shopify_get_orders_identity_resolved',
      { email_present: identity[:email].present?, phone_present: identity[:phone_number].present? }
    )

    result = orders_service.orders_for_contact(email: identity[:email], phone_number: identity[:phone_number], limit: 10)
    unless result[:ok]
      log_tool_usage('shopify_get_orders_failed', { error: result[:error] })
      return format_domain_error(result[:error])
    end

    log_tool_usage('shopify_get_orders_success', { orders_count: result[:data][:orders].length })

    format_orders(result[:data][:orders])
  rescue StandardError => e
    ChatwootExceptionTracker.new(e, account: @assistant.account).capture_exception
    'I could not fetch Shopify orders right now. Please try again shortly.'
  end
  # rubocop:enable Metrics/AbcSize

  private

  def orders_service
    @orders_service ||= Integrations::Shopify::OrdersService.new(account: @assistant.account)
  end

  def format_orders(orders)
    lines = ["Found #{orders.length} Shopify orders:"]

    orders.each_with_index do |order, index|
      lines << order_line(index, order)
      lines << "   Items: #{line_items_summary(order[:line_items])}"
    end

    lines.join("\n")
  end

  def order_line(index, order)
    [
      "#{index + 1}. #{order[:name]}",
      "Date: #{order[:created_at]}",
      "Total: #{formatted_total(order)}",
      "Payment: #{order[:financial_status]}",
      "Fulfillment: #{order[:fulfillment_status]}",
      "Admin: #{order[:admin_url]}"
    ].join(' | ')
  end

  def line_items_summary(line_items)
    items = Array(line_items)
    return 'N/A' if items.empty?

    items.map { |item| "#{item[:quantity]}x #{item[:title]}" }.join(', ')
  end

  def formatted_total(order)
    return 'N/A' if order[:total_price].blank?

    [order[:currency], order[:total_price]].compact.join(' ')
  end
end
