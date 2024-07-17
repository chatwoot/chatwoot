# == Schema Information
#
# Table name: account_plans
#
#  id                  :bigint           not null, primary key
#  extra_agents        :integer          default(0), not null
#  extra_conversations :integer          default(0), not null
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  account_id          :bigint           not null
#  product_id          :bigint           not null
#
# Indexes
#
#  index_account_plans_on_account_id                 (account_id)
#  index_account_plans_on_account_id_and_product_id  (account_id,product_id) UNIQUE
#  index_account_plans_on_product_id                 (product_id)
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id)
#  fk_rails_...  (product_id => products.id)
#
class AccountPlan < ApplicationRecord
  belongs_to :account
  belongs_to :product

  validate :product_must_be_plan

  private

  def product_must_be_plan
    return if product.plan?

    errors.add(:product, 'must be of type "plan"')
  end
end
