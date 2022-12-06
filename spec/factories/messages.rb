# frozen_string_literal: true

FactoryBot.define do
  factory :message do
    content { 'Incoming Message' }
    status { 'sent' }
    message_type { 'incoming' }
    content_type { 'text' }
    account { create(:account) }

    after(:build) do |message|
      # Setting callbacks again if the instgram_message factory works first then specs related to this factory breaks
      message.class.set_callback(:commit, :after, :execute_after_create_commit_callbacks)
      message.class.set_callback(:create, :after)
      message.class.set_callback(:commit, :after, :dispatch_update_event)
      message.sender ||= message.outgoing? ? create(:user, account: message.account) : create(:contact, account: message.account)
      message.inbox ||= message.conversation&.inbox || create(:inbox, account: message.account)
      message.conversation ||= create(:conversation, account: message.account, inbox: message.inbox)
    end
  end

  factory :instagram_message, class: 'Message' do
    content { 'Incoming Message' }
    status { 'sent' }
    message_type { 'incoming' }
    content_type { 'text' }
    account { create(:account) }
    source_id { 'instagram-message-id-1234' }

    after(:build) do |message|
      # Skipping callbacks not to send extra stub request for FB subscription and message creation send_webhook_event
      # We are testing the subscription part and send_webhook_event in instagram_event_job spec
      message.class.skip_callback(:commit, :after, :execute_after_create_commit_callbacks)
      message.class.skip_callback(:create, :after)
      message.class.skip_callback(:commit, :after, :dispatch_update_event)
      channel ||= create(:channel_instagram_fb_page, account: message.account, instagram_id: 'instagram-message-id-1234')
      message.sender ||= message.outgoing? ? create(:user, account: message.account) : create(:contact, account: message.account)
      message.inbox ||=  create(:inbox, account: message.account, channel: channel)
      message.conversation ||= create(:conversation, account: message.account, inbox: message.inbox)
    end
  end
end
