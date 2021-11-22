# == Schema Information
#
# Table name: ee_billing_product_prices
#
#  id                 :bigint           not null, primary key
#  active             :boolean          default(FALSE)
#  features           :integer          default(0), not null
#  limits             :jsonb            not null
#  stripe_nickname    :string
#  unit_amount        :integer
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  billing_product_id :bigint
#  price_stripe_id    :string
#
# Indexes
#
#  index_ee_billing_product_prices_on_billing_product_id  (billing_product_id)
#  index_ee_billing_product_prices_on_price_stripe_id     (price_stripe_id) UNIQUE
#
class Enterprise::BillingProductPrice < ApplicationRecord
  belongs_to :billing_product
end
