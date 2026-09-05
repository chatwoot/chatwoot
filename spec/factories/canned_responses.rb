# frozen_string_literal: true

FactoryBot.define do
  factory :canned_response do
    account
    sequence(:short_code) { |n| "short_code_#{n}" }
    content { 'This is a canned response' }
    visibility { :public_response }

    trait :private do
      visibility { :private_response }
    end

    trait :with_creator do
      created_by { association :user }
    end
  end
end
