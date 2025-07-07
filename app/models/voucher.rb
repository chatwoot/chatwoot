# == Schema Information
#
# Table name: vouchers
#
#  id             :bigint           not null, primary key
#  code           :string           not null
#  discount_type  :string           not null
#  discount_value :integer          not null
#  end_date       :date             not null
#  is_recurring   :boolean          default(FALSE)
#  name           :string           not null
#  start_date     :date             not null
#  usage_limit    :integer
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#
# Indexes
#
#  index_vouchers_on_code  (code) UNIQUE
#
class Voucher < ApplicationRecord
  has_and_belongs_to_many :subscription_plans
  has_many :voucher_usages

  enum discount_type: { idr: 'idr', percentage: 'percentage' }

  validates :name, :code, :discount_type, :discount_value, :start_date, :end_date, presence: true

  def active?
    Date.today.between?(start_date, end_date)
  end

  def usable_by?(account)
    return false unless active?
    return false if !is_recurring && voucher_usages.exists?(account_id: account.id)
    return false if usage_limit && voucher_usages.count >= usage_limit
    true
  end
end
