# frozen_string_literal: true

FactoryBot.define do
  factory :devise_user do
    transient do
      skip_confirmation { true }
    end

    provider { 'email' }
    name { FFaker::Name.name }
    nickname { Faker::Name.first_name }
    email { nickname + '@example.com' }
    password { "password" }
    user

    after(:build) do |devise_user, evaluator|
      devise_user.skip_confirmation! if evaluator.skip_confirmation
    end
  end
end
