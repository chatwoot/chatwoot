# == Schema Information
#
# Table name: ee_billing_products
#
#  id                  :bigint           not null, primary key
#  active              :boolean          default(FALSE)
#  product_description :string
#  product_name        :string
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  product_stripe_id   :string
#
# Indexes
#
#  index_ee_billing_products_on_product_stripe_id  (product_stripe_id) UNIQUE
#
class Enterprise::BillingProduct < ApplicationRecord
  has_many :billing_product_prices, dependent: :destroy, class_name: 'Enterprise::BillingProductPrice'
end
