# frozen_string_literal: true

# == Schema Information
#
# Table name: messages
#
#  id                        :integer          not null, primary key
#  additional_attributes     :jsonb
#  content                   :text
#  content_attributes        :json
#  content_type              :integer          default("text"), not null
#  external_source_ids       :jsonb
#  message_type              :integer          not null
#  private                   :boolean          default(FALSE), not null
#  processed_message_content :text
#  sender_type               :string
#  sentiment                 :jsonb
#  status                    :integer          default("sent")
#  transcription             :text
#  created_at                :datetime         not null
#  updated_at                :datetime         not null
#  account_id                :integer          not null
#  conversation_id           :integer          not null
#  inbox_id                  :integer          not null
#  sender_id                 :bigint
#  source_id                 :text
#
# Indexes
#
#  idx_messages_account_content_created                 (account_id,content_type,created_at)
#  index_messages_on_account_created_type               (account_id,created_at,message_type)
#  index_messages_on_account_id                         (account_id)
#  index_messages_on_account_id_and_inbox_id            (account_id,inbox_id)
#  index_messages_on_additional_attributes_campaign_id  (((additional_attributes -> 'campaign_id'::text))) USING gin
#  index_messages_on_content                            (content) USING gin
#  index_messages_on_conversation_account_type_created  (conversation_id,account_id,message_type,created_at)
#  index_messages_on_conversation_id                    (conversation_id)
#  index_messages_on_created_at                         (created_at)
#  index_messages_on_inbox_id                           (inbox_id)
#  index_messages_on_sender_type_and_sender_id          (sender_type,sender_id)
#  index_messages_on_source_id                          (source_id)
#
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
        attachment.file.attach(io: Rails.root.join('spec/assets/avatar.png').open, filename: 'avatar.png', content_type: 'image/png')
      end
    end

    trait :with_attachment do
      after(:build) do |message|
        attachment = message.attachments.new(account_id: message.account_id, file_type: :image)
        attachment.file.attach(io: Rails.root.join('spec/assets/avatar.png').open, filename: 'avatar.png', content_type: 'image/png')
      end
    end

    trait :bot_message do
      message_type { 'outgoing' }
      after(:build) do |message|
        message.sender = nil
      end
    end

    after(:build) do |message|
      message.sender ||= message.outgoing? ? create(:user, account: message.account) : create(:contact, account: message.account)
      message.inbox ||= message.conversation&.inbox || create(:inbox, account: message.account)
      message.conversation ||= create(:conversation, account: message.account, inbox: message.inbox)
    end
  end
end
