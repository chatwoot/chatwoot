FactoryBot.define do
  factory :channel_zalo do
    access_token { Faker::Alphanumeric.alphanumeric(number: 40) }
    refresh_token { Faker::Alphanumeric.alphanumeric(number: 40) }
    expires_at { 1.hour.from_now }
    account_id { 1 }
    oa_id { Faker::Number.number(digits: 15) }
    meta { {} }
  end
end
