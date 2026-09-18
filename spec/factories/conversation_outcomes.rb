FactoryBot.define do
  factory :conversation_outcome do
    account { create(:account) }
    started_at { Time.current }

    after(:build) do |outcome|
      outcome.assistant ||= create(:captain_assistant, account: outcome.account)
      outcome.inbox ||= create(:inbox, account: outcome.account)
      outcome.conversation ||= create(:conversation, account: outcome.account, inbox: outcome.inbox)
    end
  end
end
