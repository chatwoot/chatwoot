# frozen_string_literal: true

# == Schema Information
#
# Table name: notification_subscriptions
#
#  id                      :bigint           not null, primary key
#  identifier              :text
#  subscription_attributes :jsonb            not null
#  subscription_type       :integer          not null
#  created_at              :datetime         not null
#  updated_at              :datetime         not null
#  user_id                 :bigint           not null
#
# Indexes
#
#  index_notification_subscriptions_on_identifier  (identifier) UNIQUE
#  index_notification_subscriptions_on_user_id     (user_id)
#
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
