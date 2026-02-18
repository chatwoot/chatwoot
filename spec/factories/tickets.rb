# frozen_string_literal: true

FactoryBot.define do
  factory :ticket do
    sequence(:subject) { |n| "Ticket Subject #{n}" }
    description { 'Ticket description' }
    account
    contact
    conversation

    trait :with_external_ids do
      external_ids { { 'zoho' => '12345' } }
    end
  end
end
