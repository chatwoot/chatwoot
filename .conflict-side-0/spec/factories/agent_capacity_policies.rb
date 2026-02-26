FactoryBot.define do
  factory :agent_capacity_policy do
    account
    sequence(:name) { |n| "Agent Capacity Policy #{n}" }
    description { 'Test agent capacity policy' }
    exclusion_rules { {} }

    trait :with_overall_capacity do
      exclusion_rules { { 'overall_capacity' => 10 } }
    end

    trait :with_time_exclusions do
      exclusion_rules do
        {
          'hours' => [0, 1, 2, 3, 4, 5],
          'days' => %w[saturday sunday]
        }
      end
    end
  end
end
