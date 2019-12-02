# frozen_string_literal: true

FactoryBot.define do
  factory :contact_inbox do
    contact
    inbox
    source_id { SecureRandom.hex }
  end
end
