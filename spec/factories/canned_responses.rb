# frozen_string_literal: true

FactoryBot.define do
  factory :canned_response do
    content { 'Content' }
    sequence(:short_code) { |n| "CODE#{n}" }
    account
  end
end
