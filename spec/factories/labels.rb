# frozen_string_literal: true

FactoryBot.define do
  factory :label do
    account
    sequence(:title) { |n| "Label #{n}" }
  end
end
