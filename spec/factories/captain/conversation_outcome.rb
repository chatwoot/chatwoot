FactoryBot.define do
  factory :captain_conversation_outcome, class: 'Captain::ConversationOutcome' do
    account
    assistant { association :captain_assistant, account: account }
    inbox { association :inbox, account: account }
    conversation { association :conversation, account: account, inbox: inbox }
    eligible_at { Time.current }
  end
end
