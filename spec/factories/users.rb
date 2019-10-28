# frozen_string_literal: true

FactoryBot.define do
  factory :user do
    role { 'agent' }
    account

    after(:build) do |user, evaluator|
      if user.devise_user.blank?
        create(:devise_user, user: user)
      end
    end
  end
end
