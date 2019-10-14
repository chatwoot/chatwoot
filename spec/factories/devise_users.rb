# frozen_string_literal: true

FactoryBot.define do
  factory :devise_user do
    transient do
      skip_confirmation { true }
    end

    provider { 'email' }
    name { FFaker::Name.name }
    nickname { FFaker::InternetSE.user_name_from_name(name) }
    email { nickname + '@example.com' }
    password { "password" }

    after(:build) do |user, evaluator|
      user.skip_confirmation! if evaluator.skip_confirmation
    end
  end
end
