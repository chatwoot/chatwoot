# Tracks monthly AI usage per account. One row per account per month.
#
# Console usage:
#   record = AccountUsageRecord.current_for(account)
#   record.increment_ai_responses!
#   record.increment_voice_notes!     # adds 1 voice note + 6 AI responses
#   record.ai_responses_count         # => 142
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
