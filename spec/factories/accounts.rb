# frozen_string_literal: true

FactoryBot.define do
  factory :account do
    transient do
      # Default accounts get a valid, active package (nil limits = unlimited) so
      # the account-scoped request suite is not gated as inactive. Set to false
      # via the `without_package` trait for negative package tests.
      create_default_package { true }
    end

    sequence(:name) { |n| "Account #{n}" }
    status { 'active' }
    domain { 'test.com' }
    support_email { 'support@test.com' }

    after(:create) do |account, evaluator|
      next unless evaluator.create_default_package
      # Package gating lives in the enterprise edition; skip in base builds.
      next unless account.respond_to?(:current_account_package)
      # An explicitly suspended account keeps its manual suspension.
      next if account.suspended?

      create(:account_package, account: account)
    end

    trait :without_package do
      create_default_package { false }
    end
  end
end
