class Integrations::CustomApi::CreateOrUpdateOrderService
  def initialize(contact, order_data, custom_api)
    @contact = contact
    @order_data = order_data
    @custom_api = custom_api
  end

  def perform
    create_or_update_order
  end

  private

  def create_or_update_order
    order = Order.find_or_initialize_by(order_key: @order_data['id'], order_number: @order_data['orderNumber'], platform: @custom_api['name'])

    checkout = @order_data['checkout'] || {}
    contact = @contact || order.contact
    order.update!(
      contact: contact,
      account_id: @custom_api['account_id'],
      order_number: @order_data['orderNumber'],
      order_key: @order_data['id'],
      created_via: @order_data['origin'],
      platform: @custom_api['name'],
      status: map_status(@order_data['fulfillmentStatus']),
      date_created: @order_data['createdAt'],
      date_modified: @order_data['updatedAt'],
      discount_total: @order_data['totalDiscount'],
      shipping_total: @order_data['totalShipping'],
      discount_coupon: handle_coupon(@order_data['appliedDiscounts']),
      total: @order_data['total'],
      prices_include_tax: true,
      payment_method: checkout['payment']['method'],
      payment_status: map_payment_status(@order_data['financialStatus']),
      transaction_id: @order_data['invoiceId'],
      set_paid: false
    )
    order
  end

  def handle_coupon(discounts)
    discount = discounts.find { |d| d['description'] != 'PIX' }
    discount ? discount['description'] : ''
  end

  def map_status(status)
    status_mapper = {
      'FULFILLED' => 'Finalizado',
      'SHIPPED' => 'Enviado',
      'IN_PROGRESS' => 'Em Produção',
      'PARTIALLY_FULFILLED' => 'Envio de fotos finalizado',
      'PENDING_PHOTOS' => 'Compra confirmada',
      'PENDING_FULFILLMENT' => 'Aguardando atendimento',
      'CANCELED' => 'Cancelado'
    }.freeze

    status_mapper[status] || status
  end

  def map_payment_status(status)
    status_mapper = {
      'PAID' => 'Pago',
      'PENDING' => 'Pendente',
      'VOIDED' => 'Recusado'
    }.freeze

    status_mapper[status] || status
  end
end
