FactoryBot.define do
  factory :aiagent_assistant, class: 'Aiagent::Assistant' do
    sequence(:name) { |n| "Assistant #{n}" }
    description { 'Test description' }
    association :account
  end
end
