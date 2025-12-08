# frozen_string_literal: true

FactoryBot.define do
  factory :conversation_queue do
    association :account
    association :conversation
    association :inbox
    queued_at { Time.current }
    status { :waiting }

    trait :waiting do
      status { :waiting }
    end

    trait :assigned do
      status { :assigned }
    end

    trait :left do
      status { :left }
    end
  end
end
