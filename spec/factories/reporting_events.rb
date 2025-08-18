FactoryBot.define do
  factory :reporting_event do
    name { 'MyString' }
    value { 1.5 }
    value_in_business_hours { 1 }
    account_id { 1 }
    inbox_id { 1 }
    user_id { 1 }
    conversation_id { 1 }
  end
end
