# frozen_string_literal: true

# Tool for creating a shopping cart and sending payment link to customer
# Used by AI agent to help customers complete purchases
#
# Example usage in agent:
#   chat.with_tools([CreateCartTool])
#   response = chat.ask("Create a cart with 2 units of product ID 5")
#
class CreateCartTool < BaseTool
  description 'Create a shopping cart with products and send a payment link to the customer. ' \
              'Use this when customers want to buy products. ' \
              'First use product_search to find product IDs, then create the cart. ' \
              'A payment link will be automatically sent to the customer in the conversation.'

  param :items, type: :string, desc: 'JSON array of items: [{"product_id": 1, "quantity": 2}]', required: true

  def execute(items:)
    validate_context!

    if playground_mode?
      return success_response({
                                created: true,
                                message: '[Playground] Would create cart with items',
                                items: parse_items(items)
                              })
    end

    validate_catalog_enabled!
    parsed_items = parse_and_validate_items(items)

    cart = create_cart(parsed_items)

    log_and_track(parsed_items, cart)
    success_response(format_cart_response(cart))
  rescue ArgumentError => e
    log_execution({ items: items }, {}, success: false, error_message: e.message)
    error_response(e.message)
  rescue StandardError => e
    log_execution({ items: items }, {}, success: false, error_message: e.message)
    error_response("Failed to create cart: #{e.message}")
  end

  private

  def validate_catalog_enabled!
    return if current_account.catalog_settings&.enabled?

    raise ArgumentError, 'Catalog is not enabled for this account. Please enable it in Settings → Catalog.'
  end

  def parse_items(items_string)
    return items_string if items_string.is_a?(Array)

    JSON.parse(items_string)
  rescue JSON::ParserError
    raise ArgumentError, 'Invalid items format. Expected JSON array like: [{"product_id": 1, "quantity": 2}]'
  end

  def parse_and_validate_items(items_string)
    parsed = parse_items(items_string)

    raise ArgumentError, 'Items must be a non-empty array' unless parsed.is_a?(Array) && parsed.any?

    parsed.map do |item|
      product_id = item['product_id'] || item[:product_id]
      quantity = item['quantity'] || item[:quantity] || 1

      raise ArgumentError, 'Each item must have a product_id' unless product_id

      product = current_account.products.find_by(id: product_id)
      raise ArgumentError, "Product with ID #{product_id} not found" unless product

      { product_id: product_id.to_i, quantity: quantity.to_i }
    end
  end

  def create_cart(items)
    Carts::CreateService.new(
      conversation: current_conversation,
      creator: current_assistant,
      items: items
    ).perform
  end

  def format_cart_response(cart)
    {
      cart_id: cart.id,
      payment_url: cart.payment_url,
      preview_url: cart.preview_url,
      total: cart.total.to_f,
      currency: cart.currency,
      status: cart.status,
      items: cart.cart_items.map do |item|
        {
          product_id: item.product_id,
          title: item.product.title_en,
          quantity: item.quantity,
          unit_price: item.unit_price.to_f,
          total_price: item.total_price.to_f
        }
      end,
      message: 'Cart created and payment link sent to customer'
    }
  end

  def log_and_track(items, cart)
    input_data = { items: items }
    output_data = { cart_id: cart.id, total: cart.total.to_f }

    log_execution(input_data, output_data)
    track_in_context(input: input_data, output: output_data)
  end

  def track_in_context(input:, output:)
    context = Aloo::ConversationContext.find_or_create_by!(
      conversation: current_conversation,
      assistant: current_assistant
    ) do |ctx|
      ctx.context_data = {}
      ctx.tool_history = []
    end

    context.record_tool_call!(
      tool_name: 'create_cart',
      input: input,
      output: output,
      success: true
    )
  end
end
