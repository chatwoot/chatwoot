# == Schema Information
#
# Table name: shopee_orders
#
#  id             :bigint           not null, primary key
#  buyer_username :string
#  cod            :boolean
#  meta           :jsonb
#  number         :string           not null
#  status         :string
#  total_amount   :integer
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  buyer_user_id  :string
#  shop_id        :bigint           not null
#
# Indexes
#
#  index_shopee_orders_on_buyer_user_id   (buyer_user_id)
#  index_shopee_orders_on_buyer_username  (buyer_username)
#  index_shopee_orders_on_number          (number) UNIQUE
#  index_shopee_orders_on_shop_id         (shop_id)
#  index_shopee_orders_on_status          (status)
#
class Shopee::Order < ApplicationRecord
  belongs_to :contact, class_name: 'Contact', foreign_key: :buyer_user_id, optional: true, primary_key: :identifier
  has_many :order_items, class_name: 'Shopee::OrderItem'

  validates :shop_id, presence: true
  validates :number, presence: true, uniqueness: true
end
