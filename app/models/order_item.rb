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
class OrderItem < ApplicationRecord
  belongs_to :order
  belongs_to :product

  validates :quantity, presence: true, numericality: { greater_than: 0 }
  validates :unit_price, presence: true, numericality: { greater_than: 0 }
  validates :total_price, presence: true, numericality: { greater_than: 0 }
  validates :product_id, uniqueness: { scope: :order_id }

  before_validation :calculate_total_price

  private

  def calculate_total_price
    self.total_price = unit_price.to_d * quantity.to_i if unit_price.present? && quantity.present?
  end
end
