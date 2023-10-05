# frozen_string_literal: true

FactoryBot.define do
  factory :response do
    response_document
    response_source
    question { Faker::Lorem.sentence }
    answer { Faker::Lorem.paragraph }
    account
  end
end
