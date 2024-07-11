# == Schema Information
#
# Table name: products
#
#  id           :bigint           not null, primary key
#  description  :text
#  details      :jsonb
#  name         :string           not null
#  price        :decimal(10, 2)   not null
#  product_type :string           not null
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#
# Indexes
#
#  index_products_on_product_type  (product_type)
#
class Product < ApplicationRecord
  has_many :cart_items, dependent: :destroy
end
