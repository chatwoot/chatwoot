# frozen_string_literal: true

FactoryBot.define do
  factory :csat_survey_response do
    rating { 1 }
    account
    conversation
    contact
  end
end
