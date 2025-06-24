FactoryBot.define do
  factory :channel_zalo do
    access_token { 'MyString' }
    refresh_token { 'MyString' }
    expires_at { 'MyString' }
    account_id { 1 }
    oa_id { 'MyString' }
    meta { '' }
  end
end
