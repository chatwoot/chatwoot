# frozen_string_literal: true

FactoryBot.define do
  factory :response_source do
    name { Faker::Name.name }
    source_link { Faker::Internet.url }
    account
  end
end
