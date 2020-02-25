# frozen_string_literal: true

FactoryBot.define do
  factory :contact do
    sequence(:name) { |n| "Widget #{n}" }
    sequence(:email) { |n| "widget-#{n}@example.com" }
    phone_number { '+123456789011' }
    avatar { fixture_file_upload(Rails.root.join('spec/assets/avatar.png'), 'image/png') }
    account
  end
end
