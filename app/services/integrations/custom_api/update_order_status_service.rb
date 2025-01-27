class Integrations::CustomApi::UpdateOrderStatusService
  def initialize(order_key, status, tracking_code, payment_status)
    @order_key = order_key
    @status = status
    @tracking_code = tracking_code
    @payment_status = payment_status
  end

  def perform
    update_order_status
  end

  private

  def update_order_status
    order = Order.find_by(order_key: @order_key)
    order.update!(status: map_status(@status),
                  tracking_code: @tracking_code,
                  payment_status: map_payment_status(@payment_status))
    order
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
