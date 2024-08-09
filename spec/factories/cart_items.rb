FactoryBot.define do
  factory :cart_item do
    cart { nil }
    product { nil }
    quantity { 1 }
    created_at { '2024-07-11 00:47:24' }
    updated_at { '2024-07-11 00:47:24' }
  end
end
