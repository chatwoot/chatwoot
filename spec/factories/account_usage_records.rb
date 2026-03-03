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
FactoryBot.define do
  factory :account_usage_record do
    account
    period_date { Time.current.beginning_of_month.to_date }
    ai_responses_count { 0 }
    voice_notes_count { 0 }
    bonus_credits { 0 }
  end
end
