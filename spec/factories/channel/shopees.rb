FactoryBot.define do
  factory :channel_shopee, class: 'Channel::Shopee' do
    refresh_token { 'MyString' }
    access_token { 'MyString' }
    expires_at { '2025-03-25 13:14:10' }
    shop_id { 1 }
    partner_id { 1 }
  end
end
