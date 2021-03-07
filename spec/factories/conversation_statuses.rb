FactoryBot.define do
  factory :conversation_status do
    name { 'MyString' }
    custom { false }
    code { 1 }
    account { nil }
  end
end
