FactoryBot.define do
  factory :automation_rule_pending_execution do
    account
    automation_rule { association :automation_rule, account: account }
    conversation { association :conversation, account: account }
    episode_key { "status:#{Time.current.to_i}" }
    due_at { 1.hour.from_now }
    status { :pending }
  end
end
