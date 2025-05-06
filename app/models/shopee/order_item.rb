# == Schema Information
#
# Table name: shopee_order_items
#
#  id                       :bigint           not null, primary key
#  item_name                :string
#  item_sku                 :string
#  main_item                :boolean
#  meta_data                :text
#  model_discounted_price   :float
#  model_original_price     :float
#  model_quantity_purchased :integer
#  created_at               :datetime         not null
#  updated_at               :datetime         not null
#  item_id                  :bigint           not null
#  order_id                 :integer          not null
#
# Indexes
#
#  index_shopee_order_items_on_order_id  (order_id)
#
class Shopee::OrderItem < ApplicationRecord
  belongs_to :order, class_name: 'Shopee::Order'
end
