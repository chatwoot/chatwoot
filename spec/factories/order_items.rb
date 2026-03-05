# frozen_string_literal: true

# == Schema Information
#
# Table name: order_items
#
#  id          :bigint           not null, primary key
#  quantity    :integer          default(1), not null
#  total_price :decimal(10, 2)   not null
#  unit_price  :decimal(10, 2)   not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  order_id    :bigint           not null
#  product_id  :bigint           not null
#
# Indexes
#
#  index_order_items_on_order_id                 (order_id)
#  index_order_items_on_order_id_and_product_id  (order_id,product_id) UNIQUE
#  index_order_items_on_product_id               (product_id)
#
# Foreign Keys
#
#  fk_rails_...  (order_id => orders.id)
#  fk_rails_...  (product_id => products.id)
#
FactoryBot.define do
  factory :order_item do
    quantity { 1 }
    unit_price { 10.00 }
    total_price { 10.00 }

    order
    product { association :product, account: order.account }
  end
end
