# frozen_string_literal: true

FactoryBot.define do
  factory :message do
    content { 'Incoming Message' }
    status { 'sent' }
    message_type { 'incoming' }
    content_type { 'text' }
    account { create(:account) }

    trait :instagram_story_mention do
      content_attributes { { image_type: 'story_mention' } }
      after(:build) do |message|
        unless message.inbox.instagram?
          message.inbox = create(:inbox, account: message.account,
                                         channel: create(:channel_instagram_fb_page, account: message.account, instagram_id: 'instagram-123'))
        end
        attachment = message.attachments.new(account_id: message.account_id, file_type: :image, external_url: 'https://www.example.com/test.jpeg')
        attachment.file.attach(io: File.open(Rails.root.join('spec/assets/avatar.png')), filename: 'avatar.png', content_type: 'image/png')
      end
    end

    after(:build) do |message|
      message.sender ||= message.outgoing? ? create(:user, account: message.account) : create(:contact, account: message.account)
      message.inbox ||= message.conversation&.inbox || create(:inbox, account: message.account)
      message.conversation ||= create(:conversation, account: message.account, inbox: message.inbox)
    end
  end
end
