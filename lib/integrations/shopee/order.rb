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

  def list
    auth_client.query({
                        time_range_field: :create_time,
                        time_from: 1.week.ago.to_i,
                        time_to: Time.current.to_i,
                        page_size: MAX_PAGE_SIZE
                      }).get('/api/v2/order/get_order_list')
  end

  def detail(order_sn_list)
    raise 'Order SN list is empty' if order_sn_list.blank?
    raise "Order SN list is more than #{LIMIT_DETAIL_ORDER_SN}" if order_sn_list.size > LIMIT_DETAIL_ORDER_SN

    data = {
      order_sn_list: order_sn_list.join(','),
      response_optional_fields: RESPONSE_OPTIONAL_FIELDS.join(',')
    }
    auth_client.query(data).get('/api/v2/order/get_order_detail')
  end
end
