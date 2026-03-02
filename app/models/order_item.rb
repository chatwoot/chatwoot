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
