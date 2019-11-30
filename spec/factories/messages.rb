# frozen_string_literal: true

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
