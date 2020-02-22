FactoryBot.define do
  factory :agent_bot do
    account_id { 1 }
    user_id { 1 }
    name { 'MyString' }
    description { 'MyString' }
    outgoing_url { 'MyString' }
  end
end
