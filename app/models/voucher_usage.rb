# == Schema Information
#
# Table name: voucher_usages
#
#  id              :bigint           not null, primary key
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  account_id      :bigint           not null
#  subscription_id :bigint
#  voucher_id      :bigint           not null
#
# Indexes
#
#  index_voucher_usages_on_account_id       (account_id)
#  index_voucher_usages_on_subscription_id  (subscription_id)
#  index_voucher_usages_on_voucher_id       (voucher_id)
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id)
#  fk_rails_...  (subscription_id => subscriptions.id)
#  fk_rails_...  (voucher_id => vouchers.id)
#
class VoucherUsage < ApplicationRecord
  belongs_to :voucher
  belongs_to :account
  belongs_to :subscription, optional: true
end
