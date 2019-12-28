# frozen_string_literal: true

FactoryBot.define do
  factory :message do
    content { 'Message' }
    status { 'sent' }
    message_type { 'incoming' }
    account
    inbox
    conversation
    user
  end
end
