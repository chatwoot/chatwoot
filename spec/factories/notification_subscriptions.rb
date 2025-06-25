# frozen_string_literal: true

FactoryBot.define do
  factory :notification_subscription do
    user
    identifier { 'test' }
    subscription_type { 'browser_push' }
    subscription_attributes { { endpoint: 'test', auth: 'test' } }
  end
end
