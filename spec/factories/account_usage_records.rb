FactoryBot.define do
  factory :account_usage_record do
    account
    period_date { Time.current.beginning_of_month.to_date }
    ai_responses_count { 0 }
    voice_notes_count { 0 }
    bonus_credits { 0 }
  end
end
