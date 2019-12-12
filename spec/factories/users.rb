# frozen_string_literal: true

FactoryBot.define do
  factory :user do
    transient do
      email {}
    end

    role { 'agent' }
    account

    after(:build) do |user, evaluator|
      if user.devise_user.blank?
        devise_attrs = { with_user: user }

        devise_attrs[:email] = evaluator.email if evaluator.email

        create(:devise_user, devise_attrs)
      end
    end

    trait :with_avatar do
      avatar { Rack::Test::UploadedFile.new('spec/assets/avatar.png', 'image/png') }
    end
  end
end
