# frozen_string_literal: true

FactoryBot.define do
  factory :contact_email do
    contact
    account { contact.account }
    sequence(:email) { |n| "contact-email-#{n}@example.com" }
    primary { false }
  end
end
