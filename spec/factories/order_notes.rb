# frozen_string_literal: true

FactoryBot.define do
  factory :order_note do
    content { 'This is a test note' }

    order
    user { association :user, account: order.account }
    account { order.account }
  end
end
