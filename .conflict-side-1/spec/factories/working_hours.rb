# frozen_string_literal: true

FactoryBot.define do
  factory :working_hour do
    inbox
    day_of_week   { 1 }
    open_hour     { 9 }
    open_minutes  { 0 }
    close_hour    { 17 }
    close_minutes { 0 }
  end
end
