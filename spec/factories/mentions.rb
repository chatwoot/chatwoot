# frozen_string_literal: true

FactoryBot.define do
  factory :mention do
    mentioned_at { Time.current }
    account
    conversation
    user
  end
end
