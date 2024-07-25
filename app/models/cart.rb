# == Schema Information
#
# Table name: carts
#
#  id         :bigint           not null, primary key
#  status     :string           default("open"), not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  account_id :bigint           not null
#
# Indexes
#
#  index_carts_on_account_id  (account_id)
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id)
#
class Cart < ApplicationRecord
  belongs_to :account
  has_many :cart_items, dependent: :destroy
end
