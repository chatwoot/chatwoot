FactoryBot.define do
  factory :agent_activity_log do
    association :account
    association :user

    status { 'online' }
    started_at { Time.zone.now }
    ended_at { nil }
    duration_seconds { nil }
  end
end
