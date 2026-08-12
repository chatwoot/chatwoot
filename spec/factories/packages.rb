# frozen_string_literal: true

FactoryBot.define do
  factory :package do
    sequence(:name) { |n| "Package #{n}" }
    description { 'A test package' }
    status { :active }
    # Limits default to nil (unlimited) so a factory package never alters the
    # existing usage_limits behaviour. Set specific limits per-test.
    conversations_limit { nil }
    contacts_limit { nil }
    users_limit { nil }
    channels_limit { nil }
    campaign_messages_limit { nil }
  end
end
