# == Schema Information
#
# Table name: subscription_plans_vouchers
#
#  id                        :bigint           not null, primary key
#  applicable_billing_cycles :text             default(["\"monthly\"", "\"quarterly\"", "\"halfyear\"", "\"yearly\""]), is an Array
#  subscription_plan_id      :bigint           not null
#  voucher_id                :bigint           not null
#
# Indexes
#
#  index_plan_voucher  (subscription_plan_id,voucher_id)
#
class SubscriptionPlanVoucher < ApplicationRecord
  self.table_name = 'subscription_plans_vouchers'
  
  belongs_to :subscription_plan
  belongs_to :voucher

  BILLING_CYCLES = %w[monthly quarterly halfyear yearly].freeze
  
  validates :applicable_billing_cycles, presence: true
  validate :validate_billing_cycles

  # Mengecek apakah billing cycle tertentu applicable
  def applicable_to?(billing_cycle)
    applicable_billing_cycles.include?(billing_cycle.to_s) || applicable_billing_cycles.empty?
  end

  private

  def validate_billing_cycles
    return if applicable_billing_cycles.blank?
    
    invalid = applicable_billing_cycles - BILLING_CYCLES
    if invalid.any?
      errors.add(:applicable_billing_cycles, "contains invalid values: #{invalid.join(', ')}")
    end
  end
end
