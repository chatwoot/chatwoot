# == Schema Information
#
# Table name: order_items
#
#  id           :bigint           not null, primary key
#  name         :string
#  price        :string
#  quantity     :integer
#  sku          :string
#  subtotal     :string
#  subtotal_tax :string
#  tax_class    :string
#  total        :string
#  total_tax    :string
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  order_id     :integer
#  product_id   :integer
#  variation_id :integer
#
class OrderItem < ApplicationRecord
  belongs_to :order

  validates :name, :quantity, :price, presence: true
end
