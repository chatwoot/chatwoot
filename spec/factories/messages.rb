# frozen_string_literal: true

FactoryBot.define do
  factory :message do
    content { 'Incoming Message' }
    status { 'sent' }
    message_type { 'incoming' }
    content_type { 'text' }
    account { create(:account) }

    after(:build) do |message|
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
      message.class.skip_callback(:commit, :after, :execute_after_create_commit_callbacks, raise: false)
      message.class.skip_callback(:create, :after)
      channel ||= create(:channel_instagram_fb_page, account: message.account, instagram_id: 'instagram-message-id-1234')
      message.content_attributes = { image_type: 'story_mention' }
      message.sender ||= message.outgoing? ? create(:user, account: message.account) : create(:contact, account: message.account)
      message.inbox ||=  create(:inbox, account: message.account, channel: channel)
      message.conversation ||= create(:conversation, account: message.account, inbox: message.inbox)
    end
  end
end
