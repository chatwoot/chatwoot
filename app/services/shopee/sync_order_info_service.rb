class Shopee::SyncOrderInfoService
  pattr_initialize [:channel_id!, :order_number!]

  def perform
    return if order_number.blank?

    @channel = Channel::Shopee.find(channel_id)
    @order_info = fetch_order_info
    return if order_info.blank?

    Shopee::Order.transaction do
      create_or_update_order!
      sync_items!
    end

    order
  end

  private

  attr_reader :channel, :order_info, :order

  def access_params
    {
      shop_id: channel.shop_id,
      access_token: channel.access_token
    }
  end

  def fetch_order_info
    Integrations::Shopee::Order.new(access_params)
                               .detail([order_number])
                               .first
  end

  def create_or_update_order!
    @order = Shopee::Order.find_or_initialize_by(
      shop_id: channel.shop_id,
      number: order_info['order_sn']
    )
    @order.assign_attributes(
      buyer_user_id: order_info['buyer_user_id'],
      buyer_username: order_info['buyer_username'],
      status: order_info['order_status'],
      total_amount: order_info['total_amount'],
      cod: order_info['cod'],
      meta: {
        create_time: order_info['create_time'],
        pay_time: order_info['pay_time'],
        pickup_done_time: order_info['pickup_done_time'],
        ship_by_date: order_info['ship_by_date'],
        booking_sn: order_info['booking_sn'],
        cancel_by: order_info['cancel_by'],
        cancel_reason: order_info['cancel_reason'],
        buyer_cancel_reason: order_info['buyer_cancel_reason'],
        note: order_info['note'],
        message_to_seller: order_info['message_to_seller'],
        shipping_carrier: order_info['shipping_carrier'],
        days_to_ship: order_info['days_to_ship'],
        payment_method: order_info['payment_method'],
        estimated_shipping_fee: order_info['estimated_shipping_fee'],
        actual_shipping_fee: order_info['actual_shipping_fee']
      }
    )
    @order.save!
  end

  def sync_items!
    item_list = order_info['item_list'] || raise('Item list is empty')
    item_list.each do |item|
      order_item = order.order_items.find_or_initialize_by(
        shop_id: channel.shop_id,
        code: item['order_item_id']
      )
      order_item.assign_attributes(
        item_code: item['item_id'],
        item_name: item['item_name'],
        item_sku: item['item_sku'].presence || item['model_sku'],
        price: item['model_discounted_price'] || item['model_original_price'],
        meta: {
          quantity: item['model_quantity_purchased'],
          model_id: item['model_id'],
          model_name: item['model_name'],
          image_url: item.dig('image_info', 'image_url')
        }
      )
      order_item.save!
    end
  end
end
