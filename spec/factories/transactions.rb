FactoryBot.define do
  factory :transaction do
    transaction_id { "MyString" }
    user { nil }
    account { nil }
    package_type { "MyString" }
    package_name { "MyString" }
    price { "9.99" }
    duration { 1 }
    duration_unit { "MyString" }
    status { "MyString" }
    payment_method { "MyString" }
    payment_url { "MyString" }
    transaction_date { "2025-04-16 07:34:07" }
    payment_date { "2025-04-16 07:34:07" }
    expiry_date { "2025-04-16 07:34:07" }
    action { "MyString" }
    notes { "MyText" }
    metadata { "" }
  end
end
