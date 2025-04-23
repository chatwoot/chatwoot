FactoryBot.define do
  factory :shopee_voucher, class: 'Shopee::Voucher' do
    code { "MyString" }
    name { "MyString" }
    usage_quantity { 1 }
    current_usage { 1 }
    start_time { "2025-04-23 10:42:42" }
    end_time { "2025-04-23 10:42:42" }
    voucher_purpose { "MyString" }
    percentage { 1 }
    max_price { 1 }
    min_basket_price { 1 }
    discount_amount { 1 }
    target_voucher { "MyString" }
    usecase { "MyString" }
  end
end
