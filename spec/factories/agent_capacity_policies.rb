# frozen_string_literal: true

FactoryBot.define do
  factory :agent_capacity_policy, class: 'Enterprise::AgentCapacityPolicy' do
    account
    name { Faker::Name.name }
    description { Faker::Lorem.sentence }
    exclusion_rules { {} }
  end
end
