FactoryBot.define do
  factory :insight do
    sequence(:name) { |n| "Insight #{n}" }
    config { { 'key' => 'value' } }
    account
    user
  end
end
