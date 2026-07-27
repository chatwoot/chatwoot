FactoryBot.define do
  factory :failed_email_retry_batch do
    association :requested_by, factory: :super_admin
    lookback_hours { 1 }
    range_start { 1.hour.ago }
    range_end { Time.current }
  end
end
