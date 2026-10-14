FactoryBot.define do
  factory :automation_rule_pending_execution do
    account
    automation_rule { association :automation_rule, account: account }
    conversation { association :conversation, account: account }
    message { nil }
    # Derive from production so the row is episode_current for the episode the message implies.
    episode_key { AutomationRulePendingExecution.episode_key_for(conversation, message) }
    due_at { 1.hour.from_now }
    status { :pending }
  end
end
