# frozen_string_literal: true

FactoryBot.define do
  factory :contact do
    sequence(:name) { |n| "Widget #{n}" }
    sequence(:email) { |n| "widget-#{n}@example.com" }
    phone_number { '+123456789011' }
    account
  end
end
