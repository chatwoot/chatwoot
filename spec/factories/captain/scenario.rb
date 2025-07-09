FactoryBot.define do
  factory :captain_scenario, class: 'Captain::Scenario' do
    sequence(:title) { |n| "Scenario #{n}" }
    description { 'Test scenario description' }
    instruction { 'Test scenario instruction for the assistant to follow' }
    tools { [] }
    enabled { true }
    association :assistant, factory: :captain_assistant
    association :account
  end
end
