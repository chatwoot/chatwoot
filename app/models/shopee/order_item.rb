# == Schema Information
#
# Table name: shopee_order_items
#
#  id         :bigint           not null, primary key
#  code       :string           not null
#  item_code  :string           not null
#  item_name  :string           not null
#  item_sku   :string           not null
#  meta       :jsonb            not null
#  price      :integer          default(0)
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  order_id   :integer          not null
#  shop_id    :bigint           not null
#
# Indexes
#
#  index_shopee_order_items_on_code_and_order_id  (code,order_id) UNIQUE
#  index_shopee_order_items_on_order_id           (order_id)
#  index_shopee_order_items_on_shop_id            (shop_id)
#
class Shopee::OrderItem < ApplicationRecord
  belongs_to :order, class_name: 'Shopee::Order'

  validates :code, presence: true, uniqueness: { scope: :order_id }
  validates :order_id, presence: true
  validates :item_code, presence: true
  validates :item_name, presence: true
  validates :item_sku, presence: true

  default_scope { order(price: :desc) }
end
