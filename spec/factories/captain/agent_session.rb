FactoryBot.define do
  factory :captain_agent_session, class: 'Captain::AgentSession' do
    account
    association :assistant, factory: :captain_assistant
    session_type { :assistant }
    subject { create(:conversation, account: account) }

    trait :copilot do
      session_type { :copilot }
      user
      subject { create(:captain_copilot_thread, account: account, user: user) }
    end
  end
end
