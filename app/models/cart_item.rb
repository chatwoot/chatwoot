# == Schema Information
#
# Table name: cart_items
#
#  id          :bigint           not null, primary key
#  quantity    :integer          default(1), not null
#  total_price :decimal(10, 2)   not null
#  unit_price  :decimal(10, 2)   not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  cart_id     :bigint           not null
#  product_id  :bigint           not null
#
# Indexes
#
#  index_cart_items_on_cart_id                 (cart_id)
#  index_cart_items_on_cart_id_and_product_id  (cart_id,product_id) UNIQUE
#  index_cart_items_on_product_id              (product_id)
#
# Foreign Keys
#
#  fk_rails_...  (cart_id => carts.id)
#  fk_rails_...  (product_id => products.id)
#
class CartItem < ApplicationRecord
  belongs_to :cart
  belongs_to :product

  validates :quantity, presence: true, numericality: { greater_than: 0 }
  validates :unit_price, presence: true, numericality: { greater_than: 0 }
  validates :total_price, presence: true, numericality: { greater_than: 0 }
  validates :product_id, uniqueness: { scope: :cart_id }

  before_validation :calculate_total_price

  private

  def calculate_total_price
    self.total_price = unit_price.to_d * quantity.to_i if unit_price.present? && quantity.present?
  end
end
