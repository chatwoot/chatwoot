# frozen_string_literal: true

FactoryBot.define do
  factory :campaign_contact do
    campaign
    contact
    status { :pending }
    error_message { nil }
    sent_at { nil }
    metadata { {} }

    trait :sent do
      status { :sent }
      sent_at { Time.current }
    end

    trait :failed do
      status { :failed }
      error_message { 'Template not found' }
      sent_at { Time.current }
    end

    trait :skipped do
      status { :skipped }
      error_message { 'No phone number' }
    end

    trait :pending do
      status { :pending }
    end
  end
end
