# frozen_string_literal: true

FactoryBot.define do
  factory :conversation do
    status { 'open' }
    display_id { rand(10_000_000) }
    user_last_seen_at { Time.current }
    agent_last_seen_at { Time.current }
    locked { false }

    factory :complete_conversation do
      after(:build) do |conversation|
        conversation.account ||= create(:account)
        conversation.inbox ||= create(
          :inbox,
          account: conversation.account,
          channel: create(:channel_widget, account: conversation.account)
        )
        conversation.contact ||= create(:contact, account: conversation.account)
        conversation.assignee ||= create(:user)
      end
    end
  end
end
