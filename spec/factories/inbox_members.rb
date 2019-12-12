# frozen_string_literal: true

FactoryBot.define do
  factory :inbox_member do
    user
    inbox
  end
end
