# == Schema Information
#
# Table name: account_products
#
#  id         :bigint           not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  account_id :bigint           not null
#  product_id :bigint           not null
#
# Indexes
#
#  index_account_products_on_account_id  (account_id)
#  index_account_products_on_product_id  (product_id)
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id)
#  fk_rails_...  (product_id => products.id)
#
class AccountProduct < ApplicationRecord
  belongs_to :account
  belongs_to :product
end
