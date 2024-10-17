class Integrations::CustomApi::CreateOrUpdateOrderItemService
  def initialize(order, line_items)
    @order = order
    @line_items = line_items
  end

  def perform
    create_order_items
  end

  def create_order_items
    order = find_order_by_key
    @line_items.each do |item|
      order_item = OrderItem.find_or_initialize_by(order: order, product_id: item['id'], variation_id: item['variantId'])
      order_item.update!(
        order: order,
        name: item['title'],
        product_id: item['id'],
        variation_id: item['variantId'],
        quantity: item['quantity'],
        tax_class: item['tax_class'],
        subtotal: item['subtotal'],
        subtotal_tax: item['subtotal_tax'],
        total: item['total'],
        total_tax: item['total_tax'],
        sku: item['sku'],
        price: item['price']
      )
    end
  end

  def find_order_by_key
    Order.find_by(order_key: @order['order_key'])
  end
end
