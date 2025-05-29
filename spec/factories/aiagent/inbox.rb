FactoryBot.define do
  factory :aiagent_inbox, class: 'AiagentInbox' do
    association :aiagent_assistant, factory: :aiagent_assistant
    association :inbox
  end
end
