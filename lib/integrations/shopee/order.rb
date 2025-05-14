class Integrations::Shopee::Order < Integrations::Shopee::Base
  MAX_PAGE_SIZE = 100
  LIMIT_DETAIL_ORDER_SN = 50
  RESPONSE_OPTIONAL_FIELDS = [
    :buyer_user_id,
    :buyer_username,
    :estimated_shipping_fee,
    :recipient_address,
    :actual_shipping_fee,
    :goods_to_declare,
    :note,
    :note_update_time,
    :item_list,
    :pay_time,
    :dropshipper,
    :dropshipper_phone,
    :split_up,
    :buyer_cancel_reason,
    :cancel_by,
    :cancel_reason,
    :actual_shipping_fee_confirmed,
    :buyer_cpf_id,
    :fulfillment_flag,
    :pickup_done_time,
    :package_list,
    :shipping_carrier,
    :payment_method,
    :total_amount,
    :buyer_username,
    :invoice_data,
    :order_chargeable_weight_gram,
    :return_request_due_date,
    :edt
  ].freeze
  DEFAULT_TIME_FROM = 1.day
  DEFAULT_TIME_FIELD = :update_time

  def all(params = {})
    orders = []
    final_params = {
      time_range_field: params[:time_range_field] || DEFAULT_TIME_FIELD,
      time_from: params[:time_from] || DEFAULT_TIME_FROM.ago.to_i,
      time_to: params[:time_to] || Time.current.to_i,
      page_size: params[:page_size] || MAX_PAGE_SIZE,
      cursor: params[:cursor] || nil,
    }
    loop do
      response = page_orders(final_params)
      orders += response['order_list'].to_a
      if response['order_list'].blank? || response['next_cursor'].blank?
        break
      else
        final_params[:cursor] = response['next_cursor']
      end
    end
    return orders
  end

  def detail(order_sn_list)
    raise 'Order SN list is empty' if order_sn_list.blank?
    raise "Order SN list is more than #{LIMIT_DETAIL_ORDER_SN}" if order_sn_list.size > LIMIT_DETAIL_ORDER_SN

    params = {
      order_sn_list: order_sn_list.join(','),
      response_optional_fields: RESPONSE_OPTIONAL_FIELDS.join(',')
    }
    auth_client
      .query(params)
      .get('/api/v2/order/get_order_detail')
      .dig('response', 'order_list')
  end

  private

  def page_orders(params)
    auth_client
      .query(params)
      .get('/api/v2/order/get_order_list')
      .dig('response')
  end
end
