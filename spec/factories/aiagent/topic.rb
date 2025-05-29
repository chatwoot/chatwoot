FactoryBot.define do
  factory :aiagent_topic, class: 'Aiagent::Topic' do
    sequence(:name) { |n| "Topic #{n}" }
    description { 'Test description' }
    association :account
  end
end
