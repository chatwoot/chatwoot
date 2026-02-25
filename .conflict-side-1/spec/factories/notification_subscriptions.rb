# frozen_string_literal: true

FactoryBot.define do
  factory :notification_subscription do
    user
    identifier { 'test' }
    subscription_type { 'browser_push' }
    subscription_attributes { { endpoint: 'test', auth: 'test' } }

    trait :browser_push do
      subscription_type { 'browser_push' }
    end

    trait :fcm do
      subscription_type { 'fcm' }
    end
  end
end
