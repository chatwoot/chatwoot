# frozen_string_literal: true

FactoryBot.define do
  factory :inbox_capacity_limit, class: 'Enterprise::InboxCapacityLimit' do
    association :agent_capacity_policy, factory: :agent_capacity_policy
    inbox
    conversation_limit { 5 }
  end
end
