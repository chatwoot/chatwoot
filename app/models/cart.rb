class Cart < ApplicationRecord
  belongs_to :account
  has_many :cart_items, dependent: :destroy
end
