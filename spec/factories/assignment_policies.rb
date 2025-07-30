# frozen_string_literal: true

FactoryBot.define do
  factory :assignment_policy do
    account
    sequence(:name) { |n| "Assignment Policy #{n}" }
    description { 'Test assignment policy' }
    assignment_order { :round_robin }
    conversation_priority { :earliest_created }
    fair_distribution_limit { 10 }
    fair_distribution_window { 3600 }
    enabled { true }

    trait :balanced do
      assignment_order { :balanced }
    end

    trait :disabled do
      enabled { false }
    end

    trait :longest_waiting do
      conversation_priority { :longest_waiting }
    end

    trait :with_high_limit do
      fair_distribution_limit { 50 }
    end

    trait :with_short_window do
      fair_distribution_window { 300 } # 5 minutes
    end
  end
end