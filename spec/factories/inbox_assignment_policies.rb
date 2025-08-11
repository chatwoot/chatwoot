# frozen_string_literal: true

FactoryBot.define do
  factory :inbox_assignment_policy do
    inbox
    assignment_policy

    # Ensure inbox and policy belong to same account
    after(:build) do |inbox_policy|
      inbox_policy.assignment_policy.account = inbox_policy.inbox.account if inbox_policy.inbox && inbox_policy.assignment_policy
    end
  end
end
