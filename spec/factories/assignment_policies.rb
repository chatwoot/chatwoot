FactoryBot.define do
  factory :assignment_policy do
    account
    sequence(:name) { |n| "Assignment Policy #{n}" }
    description { 'Test assignment policy description' }
    assignment_order { 0 }
    conversation_priority { 0 }
    fair_distribution_limit { 10 }
    fair_distribution_window { 3600 }
    enabled { true }
  end
end
