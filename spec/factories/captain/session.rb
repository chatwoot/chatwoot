FactoryBot.define do
  factory :captain_session, class: 'Captain::Session' do
    account
    association :assistant, factory: :captain_assistant
    session_type { :assistant }
    subject_id { create(:conversation, account: account).id }

    trait :copilot do
      session_type { :copilot }
      user
      subject_id { create(:captain_copilot_thread, account: account, user: user).id }
    end
  end
end
