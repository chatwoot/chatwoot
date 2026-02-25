# frozen_string_literal: true

FactoryBot.define do
  factory :account_user do
    account
    user
    role { 'agent' }
  end
end
