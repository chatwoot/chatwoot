# frozen_string_literal: true

FactoryBot.define do
  factory :user do
    transient do
      skip_confirmation { true }
      role { 'agent' }
      auto_offline { true }
      account { nil }
      inviter { nil }
    end

    provider { 'email' }
    uid { SecureRandom.uuid }
    name { Faker::Name.name }
    display_name { Faker::Name.first_name }
    email { display_name + "@#{SecureRandom.uuid}.com" }
    password { 'Password1!' }

    after(:build) do |user, evaluator|
      user.skip_confirmation! if evaluator.skip_confirmation
      if evaluator.account
        create(:account_user, user: user, account: evaluator.account, role: evaluator.role, inviter: evaluator.inviter,
                              auto_offline: evaluator.auto_offline)
      end
    end

    trait :with_avatar do
      avatar { fixture_file_upload(Rails.root.join('spec/assets/avatar.png'), 'image/png') }
    end

    trait :administrator do
      role { 'administrator' }
    end

    trait :with_mfa_enabled do
      after(:create) do |user|
        user.update!(
          otp_secret: user.class.generate_random_base32,
          otp_required_for_login: true
        )
        user.generate_backup_codes!
      end
    end

    trait :with_mfa_setup_pending do
      after(:create) do |user|
        user.update!(
          otp_secret: user.class.generate_random_base32,
          otp_required_for_login: false
        )
      end
    end
  end
end
