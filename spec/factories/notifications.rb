# frozen_string_literal: true

FactoryBot.define do
  factory :notification do
    primary_actor { create(:conversation, account: account) }
    notification_type { 'conversation_assignment' }
    user
    account
    read_at { nil }
    snoozed_until { nil }
  end

  trait :read do
    read_at { DateTime.now.utc - 3.days }
  end

  trait :snoozed do
    snoozed_until { DateTime.now.utc + 3.days }
  end
end
