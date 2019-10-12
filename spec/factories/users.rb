# frozen_string_literal: true

FactoryBot.define do
  factory :user do
    provider { 'email' }
    uid { SecureRandom.uuid }
    name { 'John Smith' }
    nickname { 'jsmith' }
    email { 'john.smith@example.com' }
    role { 'agent' }
    password { "password" }
    account
  end
end
