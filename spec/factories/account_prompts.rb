# frozen_string_literal: true

FactoryBot.define do
  factory :account_prompt do
    sequence(:prompt_key) { |n| "prompt_#{n}" }
    text { 'This is a sample prompt text for testing purposes.' }
    account

    trait :greeting do
      prompt_key { 'greeting' }
      text { 'Hello! How can I help you today?' }
    end

    trait :closing do
      prompt_key { 'closing' }
      text { 'Thank you for contacting us. Have a great day!' }
    end

    trait :with_long_text do
      text { 'A' * 1000 } # Long text for testing text field limits
    end

    trait :with_special_characters do
      text { 'Hello! @#$%^&*()_+{}|:"<>?[]\\;\',./ Testing special characters.' }
    end
  end
end