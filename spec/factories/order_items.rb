# frozen_string_literal: true

FactoryBot.define do
  factory :order_item do
    quantity { 1 }
    unit_price { 10.00 }
    total_price { 10.00 }

    order
    product { association :product, account: order.account }
  end
end
