FactoryBot.define do
  factory :agent_bot_inbox do
    inbox
    agent_bot
    status { 'active' }
  end
end
