FactoryBot.define do
  factory :automation_rule_pending_execution do
    account
    automation_rule { association :automation_rule, account: account }
    conversation { association :conversation, account: account }
    # Derive from production so the row is episode_current (matches the conversation's status).
    episode_key { AutomationRulePendingExecution.episode_key_for(conversation, nil) }
    due_at { 1.hour.from_now }
    status { :pending }
  end
end
