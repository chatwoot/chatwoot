# frozen_string_literal: true

FactoryBot.define do
  factory :notification do
    primary_actor { create(:conversation, account: account) }
    notification_type { 'conversation_assignment' }
    user
    account
  end
end
