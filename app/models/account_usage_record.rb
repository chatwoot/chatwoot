# Tracks monthly AI usage per account. One row per account per month.
#
# Console usage:
#   record = AccountUsageRecord.current_for(account)
#   record.increment_ai_responses!
#   record.increment_voice_notes!     # adds 1 voice note + 6 AI responses
#   record.ai_responses_count         # => 142
#
# == Schema Information
#
# Table name: account_usage_records
#
#  id                 :bigint           not null, primary key
#  ai_responses_count :integer          default(0), not null
#  bonus_credits      :integer          default(0), not null
#  overage_count      :integer          default(0), not null
#  period_date        :date             not null
#  voice_notes_count  :integer          default(0), not null
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  account_id         :bigint           not null
#
# Indexes
#
#  idx_usage_account_period  (account_id,period_date) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id)
#
class AccountUsageRecord < ApplicationRecord
  belongs_to :account

  validates :period_date, presence: true, uniqueness: { scope: :account_id }

  def self.current_for(account)
    find_or_create_by!(account: account, period_date: Time.current.beginning_of_month.to_date)
  end

  def increment_ai_responses!(count = 1)
    increment!(:ai_responses_count, count)
  end

  def increment_voice_notes!(count = 1)
    # 1 voice note = 6 AI responses
    increment!(:voice_notes_count, count)
    increment!(:ai_responses_count, count * 6)
  end
end
