# frozen_string_literal: true

FactoryBot.define do
  factory :queue_statistic do
    association :account

    date { Date.current }

    total_queued { 0 }
    total_assigned { 0 }
    total_left { 0 }
    average_wait_time_seconds { 0 }
    max_wait_time_seconds { 0 }
  end
end
