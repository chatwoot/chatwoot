class Product < ApplicationRecord
  has_many :cart_items, dependent: :destroy
end
