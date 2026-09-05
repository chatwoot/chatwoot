# frozen_string_literal: true

FactoryBot.define do
  factory :priority_group do
    account
    sequence(:name) { |n| "Priority Group #{n}" }
  end
end
