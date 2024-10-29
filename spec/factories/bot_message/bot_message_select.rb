# frozen_string_literal: true

FactoryBot.define do
  factory :bot_message_select, class: Hash do
    title { Faker::Book.name }
    value { Faker::Book.name }

    initialize_with { attributes }
  end
end
