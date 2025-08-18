FactoryBot.define do
  factory :leave_record do
    account
    user
    start_date { 1.week.from_now.to_date }
    end_date { 2.weeks.from_now.to_date }
    leave_type { :annual }
    status { :pending }
    reason { 'Annual vacation leave' }

    trait :sick do
      leave_type { :sick }
      reason { 'Sick leave for medical treatment' }
    end

    trait :emergency do
      leave_type { :emergency }
      reason { 'Emergency family matter' }
    end

    trait :other do
      leave_type { :other }
      reason { 'Other type of leave' }
    end

    trait :approved do
      status { :approved }
      approved_by { association(:user) }
      approved_at { 1.day.ago }
    end

    trait :rejected do
      status { :rejected }
      approved_by { association(:user) }
      approved_at { 1.day.ago }
    end

    trait :past_dates do
      start_date { 2.weeks.ago.to_date }
      end_date { 1.week.ago.to_date }
      status { :approved }  # Past dates should only be used with approved status
    end
  end
end
