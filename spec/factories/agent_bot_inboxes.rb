FactoryBot.define do
  factory :agent_bot_inbox do
    inbox_id { 1 }
    agent_bot_id { 1 }
    status { 'MyString' }
    string { 'MyString' }
  end
end
