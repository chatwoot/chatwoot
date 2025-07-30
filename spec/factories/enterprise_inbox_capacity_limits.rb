# frozen_string_literal: true

FactoryBot.define do
  factory :enterprise_inbox_capacity_limit, class: 'Enterprise::InboxCapacityLimit' do
    association :agent_capacity_policy, factory: :enterprise_agent_capacity_policy
    inbox
    conversation_limit { 10 }

    trait :low_limit do
      conversation_limit { 3 }
    end

    trait :high_limit do
      conversation_limit { 50 }
    end

    trait :max_limit do
      conversation_limit { 1000 }
    end

    # Ensure inbox and policy belong to same account
    after(:build) do |limit|
      if limit.inbox && limit.agent_capacity_policy
        limit.agent_capacity_policy.account = limit.inbox.account
      end
    end
  end
end