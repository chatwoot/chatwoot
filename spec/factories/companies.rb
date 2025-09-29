# frozen_string_literal: true

FactoryBot.define do
  factory :company do
    sequence(:name) { |n| "Company #{n}" }
    sequence(:domain) { |n| "company#{n}.com" }
    description { 'A sample company description' }
    avatar { 'https://example.com/avatar.png' }
    account

    trait :without_domain do
      domain { nil }
    end

    trait :without_avatar do
      avatar { nil }
    end

    trait :with_long_description do
      description { 'A' * 500 }
    end
  end
end
