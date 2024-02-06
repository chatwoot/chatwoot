# frozen_string_literal: true

FactoryBot.define do
  factory :response_document do
    response_source
    content { Faker::Lorem.paragraph }
    document_link { Faker::Internet.url }
    account
  end
end
