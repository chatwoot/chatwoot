# frozen_string_literal: true

FactoryBot.define do
  factory :enterprise_agent_capacity_policy, class: 'Enterprise::AgentCapacityPolicy' do
    account
    sequence(:name) { |n| "Capacity Policy #{n}" }
    description { 'Test capacity policy' }
    exclusion_rules { {} }

    trait :with_label_exclusion do
      exclusion_rules { { 'labels' => %w[vip urgent] } }
    end

    trait :with_time_exclusion do
      exclusion_rules { { 'hours_threshold' => 24 } }
    end

    trait :with_combined_exclusions do
      exclusion_rules do
        {
          'labels' => %w[vip urgent],
          'hours_threshold' => 48
        }
      end
    end
  end
end
