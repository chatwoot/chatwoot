FactoryBot.define do
  factory :captain_conversation_outcome, class: 'Captain::ConversationOutcome' do
    account { create(:account) }

    after(:build) do |outcome|
      outcome.assistant ||= create(:captain_assistant, account: outcome.account)
      outcome.inbox ||= create(:inbox, account: outcome.account)
      outcome.conversation ||= create(:conversation, account: outcome.account, inbox: outcome.inbox)
    end
  end
end
