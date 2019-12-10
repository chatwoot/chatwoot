# frozen_string_literal: true

FactoryBot.define do
  factory :user do
    transient do
      skip_confirmation { true }
    end

    provider { 'email' }
    uid { SecureRandom.uuid }
    name { Faker::Name.name }
    nickname { Faker::Name.first_name }
    email { nickname + '@example.com' }
    role { 'agent' }
    password { 'password' }
    account

    after(:build) do |user, evaluator|
      user.skip_confirmation! if evaluator.skip_confirmation
    end

    trait :with_avatar do
      avatar { Rack::Test::UploadedFile.new('spec/assets/avatar.png', 'image/png') }
    end
  end
end
