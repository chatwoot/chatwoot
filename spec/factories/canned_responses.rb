# frozen_string_literal: true

FactoryBot.define do
  factory :canned_response do
    content { 'Content' }
    content_format { 'markdown' }
    sequence(:short_code) { |n| "CODE#{n}" }
    account
  end
end
