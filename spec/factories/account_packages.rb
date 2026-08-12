# frozen_string_literal: true

FactoryBot.define do
  factory :account_package do
    association :account
    association :package
    starts_at { 1.month.ago }
    ends_at { 1.month.from_now }
  end
end
