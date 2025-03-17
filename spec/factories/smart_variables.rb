FactoryBot.define do
  factory :smart_variable do
    sequence(:name) { |n| "SmartVariable#{n}" }
    data { { key: "value" } }
  end
end
