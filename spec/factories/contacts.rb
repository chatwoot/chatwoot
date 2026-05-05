# frozen_string_literal: true

FactoryBot.define do
  factory :contact do
    sequence(:name) { |n| "Contact #{n}" }
    account

    trait :with_avatar do
      avatar { fixture_file_upload(Rails.root.join('spec/assets/avatar.png'), 'image/png') }
    end

    trait :with_email do
      sequence(:email) { |n| "contact-#{n}@example.com" }
    end

    trait :with_phone_number do
      phone_number { Faker::PhoneNumber.cell_phone_in_e164 }
    end

    trait :with_account_owner do
      after(:build) do |contact|
        contact.account_owner ||= create(:user, account: contact.account)
      end
    end
  end
end
