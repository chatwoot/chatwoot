# frozen_string_literal: true

FactoryBot.define do
  factory :contact_phone do
    contact
    account { contact.account }
    sequence(:phone_number) { |n| "+1555123#{n.to_s.rjust(4, '0')}" }
  end
end
