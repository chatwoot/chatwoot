# frozen_string_literal: true

FactoryBot.define do
  factory :account do
    sequence(:name) { |n| "Account #{n}" }
    status { 'active' }
    custom_email_domain_enabled { false }
    domain { 'test.com' }
    support_email { 'support@test.com' }
  end
end
