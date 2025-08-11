# frozen_string_literal: true

FactoryBot.define do
  factory :leave do
    account
    user
    start_date { Date.current + 1.day }
    end_date { Date.current + 7.days }
    leave_type { 'vacation' }
    status { 'pending' }
    reason { 'Annual vacation' }

    trait :approved do
      status { 'approved' }
      approved_by { create(:user) }
      approved_at { Time.current }
    end

    trait :rejected do
      status { 'rejected' }
      approved_by { create(:user) }
      approved_at { Time.current }
    end

    trait :cancelled do
      status { 'cancelled' }
    end

    trait :active do
      approved
      start_date { Date.current }
      end_date { Date.current + 7.days }
    end

    trait :past do
      approved
      start_date { Date.current - 14.days }
      end_date { Date.current - 7.days }
    end

    trait :future do
      approved
      start_date { Date.current + 7.days }
      end_date { Date.current + 14.days }
    end

    trait :sick_leave do
      leave_type { 'sick' }
      reason { 'Medical reasons' }
    end

    trait :personal_leave do
      leave_type { 'personal' }
      reason { 'Personal matters' }
    end
  end
end
