# frozen_string_literal: true

FactoryBot.define do
  factory :user do
    transient do
      skip_confirmation { true }
      role { 'agent' }
      account { nil }
      inviter { nil }
    end

    provider { 'email' }
    uid { SecureRandom.uuid }
    name { Faker::Name.name }
    display_name { Faker::Name.first_name }
    email { display_name + "@#{SecureRandom.uuid}.com" }
    password { 'password' }

    after(:build) do |user, evaluator|
      user.skip_confirmation! if evaluator.skip_confirmation
      create(:account_user, user: user, account: evaluator.account, role: evaluator.role, inviter: evaluator.inviter) if evaluator.account
    end

    trait :with_avatar do
      avatar { Rack::Test::UploadedFile.new('spec/assets/avatar.png', 'image/png') }
    end

    trait :administrator do
      role { 'administrator' }
    end
  end
end
