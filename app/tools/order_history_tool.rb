# frozen_string_literal: true

# Tool for retrieving a contact's order history
# Used by AI agent to answer questions about past orders and order status
#
# Example usage in agent:
#   chat.with_tools([OrderHistoryTool])
#   response = chat.ask("What are the customer's recent orders?")
#
class OrderHistoryTool < BaseTool
  description 'Retrieve the order history for the current customer. ' \
              'Use this when: ' \
              '1) The customer asks about their past orders or order status, ' \
              '2) The customer wants to know if their order was paid, ' \
              '3) You need to look up an order for the customer. ' \
              'Returns the most recent orders with their items and payment status.'

  param :status, type: :string,
                 desc: 'Optional filter by order status: initiated, pending, paid, failed, expired, or cancelled',
                 required: false

  def execute(status: nil)
    validate_context!

    if playground_mode?
      return success_response({
                                message: '[Playground] Would retrieve order history for the customer',
                                orders: []
                              })
    end

    contact = resolve_contact!
    orders = fetch_orders(contact, status)

    success_response({
                       contact_name: contact.name,
                       orders: orders.map { |order| format_order(order) }
                     })
  rescue ArgumentError => e
    error_response(e.message)
  rescue StandardError => e
    error_response("Failed to retrieve order history: #{e.message}")
  end

  private

  def resolve_contact!
    contact = current_contact || current_conversation&.contact
    raise ArgumentError, 'No contact associated with this conversation' unless contact

    contact
  end

  def fetch_orders(contact, status)
    scope = current_account.orders.where(contact_id: contact.id).recent.includes(order_items: :product)
    scope = scope.by_status(status) if status.present?
    scope.limit(10)
  end

  def format_order(order)
    {
      id: order.id,
      external_payment_id: order.external_payment_id,
      status: order.status,
      total: order.total.to_f,
      currency: order.currency,
      payment_url: order.payment_url,
      created_at: order.created_at.iso8601,
      items: order.order_items.map { |item| format_item(item) }
    }
  end

  def format_item(item)
    {
      product_name: item.product.title_en,
      quantity: item.quantity,
      unit_price: item.unit_price.to_f,
      total_price: item.total_price.to_f
    }
  end
end
