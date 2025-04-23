FactoryBot.define do
  factory :shopee_order, class: 'Shopee::Order' do
    number { "MyString" }
    status { "MyString" }
    cod { false }
    total_amount { 1 }
    shipping_carrier { "MyString" }
    payment_method { "MyString" }
    estimated_shipping_fee { 1 }
    message_to_seller { "MyString" }
    create_time { "2025-04-22 17:44:24" }
    days_to_ship { 1 }
    note { "MyString" }
    actual_shipping_fee { 1 }
    recipient_address { "MyText" }
    pay_time { "2025-04-22 17:44:24" }
    cancel_reason { "MyString" }
    cancel_by { "MyString" }
    buyer_cancel_reason { "MyString" }
    pickup_done_time { "2025-04-22 17:44:24" }
    booking_sn { "MyString" }
  end
end
