# frozen_string_literal: true

# == Schema Information
#
# Table name: messages
#
#  id              :integer          not null, primary key
#  content         :text
#  message_type    :integer          not null
#  private         :boolean          default(FALSE)
#  status          :integer          default("sent")
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  account_id      :integer          not null
#  conversation_id :integer          not null
#  fb_id           :string
#  inbox_id        :integer          not null
#  user_id         :integer
#
# Indexes
#
#  index_messages_on_conversation_id  (conversation_id)
#


FactoryBot.define do
  factory :message do
    content { 'Message' }
    status { 'sent' }
    message_type { 'incoming' }
    fb_id { SecureRandom.uuid }
    account
    inbox
    conversation
    user
  end
end
