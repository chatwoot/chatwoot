# frozen_string_literal: true

FactoryBot.define do
  factory :devise_user do
    transient do
      skip_confirmation { true }
      with_user { nil }
    end

    provider { 'email' }
    name { FFaker::Name.name }
    nickname { Faker::Name.first_name }
    email { nickname + '@example.com' }
    password { "password" }
    
    user do
      with_user ? with_user : create(:user)
    end

    after(:build) do |devise_user, evaluator|
      devise_user.skip_confirmation! if evaluator.skip_confirmation
    end
  end
end
