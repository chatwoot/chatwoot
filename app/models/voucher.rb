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
  has_many :subscription_plan_vouchers
  has_many :subscription_plans, through: :subscription_plan_vouchers
  has_many :voucher_usages

  enum discount_type: { idr: 'idr', percentage: 'percentage' }

  validates :name, :code, :discount_type, :discount_value, :start_date, :end_date, presence: true

  def active?
    Date.today.between?(start_date, end_date)
  end

  # Cek apakah voucher applicable untuk plan dan billing cycle tertentu
  def applicable_to_plan_and_cycle?(plan_id, billing_cycle)
    subscription_plan_vouchers
      .where(subscription_plan_id: plan_id)
      .where("? = ANY(applicable_billing_cycles) OR applicable_billing_cycles = '{}'", billing_cycle.to_s)
      .exists?
  end

  # Cek apakah voucher bisa digunakan oleh account untuk plan dan billing cycle tertentu
  def usable_by?(account, subscription_plan_id = nil, billing_cycle = nil)
    return false unless active?
    
    # Jika subscription_plan_id dan billing_cycle disediakan, cek applicable
    if subscription_plan_id.present? && billing_cycle.present?
      return false unless applicable_to_plan_and_cycle?(subscription_plan_id, billing_cycle)
    end
    
    # Cek apakah sudah pernah digunakan (jika tidak recurring)
    return false if !is_recurring && voucher_usages.exists?(account_id: account.id)
    
    # Cek usage limit
    return false if usage_limit && voucher_usages.count >= usage_limit
    
    true
  end

  # Method backward compatible untuk kasus tanpa billing cycle
  def usable_by_account?(account)
    usable_by?(account)
  end
end
