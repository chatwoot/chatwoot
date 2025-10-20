# frozen_string_literal: true

FactoryBot.define do
  factory :appointment do
    location { 'Office' }
    description { 'Meeting with client' }
    start_time { Time.zone.now }
    end_time { 1.hour.from_now }
    association :contact

    # Automatically set account from contact if not provided
    account { contact&.account || association(:account) }
  end
end
