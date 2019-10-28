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
        devise_attrs = {with_user: user}

        if evaluator.email
          devise_attrs.merge!(email: evaluator.email)
        end

        create(:devise_user, devise_attrs)
      end
    end
  end
end
