json.payload do # rubocop:disable Metrics/BlockLength
  json.array! @orders do |order| # rubocop:disable Metrics/BlockLength
    json.id order.id
    json.order_number order.order_number
    json.contact_id order.contact_id
    json.order_key order.order_key
    json.created_via order.created_via
    json.platform order.platform
    json.status order.status
    json.currency order.currency
    json.date_created order.date_created.strftime('%Y-%m-%d %H:%M:%S') if order.date_created.present?
    json.date_created_gmt order.date_created_gmt.strftime('%Y-%m-%d %H:%M:%S') if order.date_created_gmt.present?
    json.date_modified order.date_modified.strftime('%Y-%m-%d %H:%M:%S') if order.date_modified.present?
    json.date_modified_gmt order.date_modified_gmt.strftime('%Y-%m-%d %H:%M:%S') if order.date_modified_gmt.present?
    json.discount_total order.discount_total
    json.discount_tax order.discount_tax
    json.discount_coupon order.discount_coupon
    json.shipping_total order.shipping_total
    json.shipping_tax order.shipping_tax
    json.cart_tax order.cart_tax
    json.total order.total
    json.total_tax order.total_tax
    json.prices_include_tax order.prices_include_tax
    json.contact_id order.contact_id
    json.customer_ip_address order.customer_ip_address
    json.customer_user_agent order.customer_user_agent
    json.customer_note order.customer_note
    json.payment_method order.payment_method
    json.payment_method_title order.payment_method_title
    json.payment_status order.payment_status
    json.transaction_id order.transaction_id
    json.date_paid order.date_paid.strftime('%Y-%m-%d %H:%M:%S') if order.date_paid.present?
    json.date_paid_gmt order.date_paid_gmt.strftime('%Y-%m-%d %H:%M:%S') if order.date_paid_gmt.present?
    json.date_completed order.date_completed.strftime('%Y-%m-%d %H:%M:%S') if order.date_completed.present?
    json.date_completed_gmt order.date_completed_gmt.strftime('%Y-%m-%d %H:%M:%S') if order.date_completed_gmt.present?
    json.cart_hash order.cart_hash
    json.set_paid order.set_paid

    json.contact order.contact

    json.order_items order.order_items do |item|
      json.id item.id
      json.name item.name
      json.product_id item.product_id
      json.variation_id item.variation_id
      json.quantity item.quantity
      json.tax_class item.tax_class
      json.subtotal item.subtotal
      json.subtotal_tax item.subtotal_tax
      json.total item.total
      json.total_tax item.total_tax
      json.sku item.sku
      json.price item.price
    end

    json.created_at order.created_at.strftime('%Y-%m-%d %H:%M:%S')
    json.updated_at order.updated_at.strftime('%Y-%m-%d %H:%M:%S')
  end
end
