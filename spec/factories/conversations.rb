# frozen_string_literal: true

FactoryBot.define do
  factory :conversation do
    status { 'open' }
    agent_last_seen_at { Time.current }
    identifier { SecureRandom.hex }

    after(:build) do |conversation|
      conversation.account ||= create(:account)
      conversation.inbox ||= create(
        :inbox,
        account: conversation.account,
        channel: create(:channel_widget, account: conversation.account)
      )
      conversation.contact ||= create(:contact, :with_email, account: conversation.account)
      conversation.contact_inbox ||= create(:contact_inbox, contact: conversation.contact, inbox: conversation.inbox)
    end
  end
end
