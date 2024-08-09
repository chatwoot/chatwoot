FactoryBot.define do
  factory :ticket do
    title { 'MyString' }
    description { 'MyText' }
    status { 1 }
    resolved_at { '2024-07-30 00:53:06' }
    assigned_to { '' }
    user { nil }
    conversation { nil }
  end
end
