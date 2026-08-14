# frozen_string_literal: true

FactoryBot.define do
  factory :addon do
    sequence(:name) { |n| "Add-on #{n}" }
    description { 'A test add-on' }
    status { :active }
    association :account
    association :package
    starts_at { 1.month.ago }
    ends_at { 1.month.from_now }
    # Limit boosts default to nil ("no boost") so a factory add-on never alters
    # the existing usage_limits behaviour. Set specific boosts per-test.
    users_limit { nil }
    channels_limit { nil }
    contacts_limit { nil }
    conversations_limit { nil }
    campaign_messages_limit { nil }
  end
end
