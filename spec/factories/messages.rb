# frozen_string_literal: true

FactoryBot.define do
  factory :message do
    content { 'Incoming Message' }
    status { 'sent' }
    message_type { 'incoming' }
    content_type { 'text' }
    account { create(:account) }

    after(:build) do |message|
      message.sender ||= create(:user, account: message.account)
      message.inbox ||= create(:inbox, account: message.account)
      message.conversation ||= create(:conversation, account: message.account, inbox: message.inbox)
    end
  end
end
