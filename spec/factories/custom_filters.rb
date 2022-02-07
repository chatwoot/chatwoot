# frozen_string_literal: true

FactoryBot.define do
  factory :custom_filter do
    sequence(:name) { |n| "Custom Filter #{n}" }
    filter_type { 0 }
    query { { labels: ['customer-support'], status: 'open' } }
    user
    account
  end
end
