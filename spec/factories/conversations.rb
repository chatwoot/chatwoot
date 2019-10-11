# frozen_string_literal: true

FactoryBot.define do
  factory :conversation do
    account
    status { 'open' }
    association :sender, factory: :contact
    # association :assignee, factory: :user
    display_id { SecureRandom.uuid }
    user_last_seen_at { Time.current }
    agent_last_seen_at { Time.current }
    locked { false }

    factory :complete_conversation do
      after(:build) do |conversation|
        account = create(:account)
        channel_widget = create(:channel_widget, account: account)
        inbox = create(:inbox, account: account, channel: channel_widget)
        user = create(:user)
        conversation.account = account
        conversation.inbox = inbox
        conversation.assignee = user
      end
    end
  end
end
