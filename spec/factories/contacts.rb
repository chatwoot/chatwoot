# frozen_string_literal: true

FactoryBot.define do
  factory :contact do
    sequence(:name) { |n| "Widget #{n}" }
    sequence(:email) { |n| "widget-#{n}@example.com" }
    phone_number { "+123456789011" }
    source_id { rand(100) }
    chat_channel { "chat_channel" }
    account
    inbox
  end
end



