FactoryBot.define do
  factory :captain_assistant, class: 'Captain::Assistant' do
    sequence(:name) { |n| "Assistant #{n}" }
    description { 'Test description' }
    association :account
    config { { 'product_name' => 'Test Product', 'feature_memory' => true, 'feature_faq' => true } }
  end
end
