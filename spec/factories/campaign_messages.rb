FactoryBot.define do
  factory :campaign_message do
    campaign { nil }
    contact { nil }
    message_id { 'wamid.HBgMOTE5NzQ1Nzg2MjU3FQIAERgSRUVGNDIzQ0UxODZERUJCMDg0AA==' }
    status { 'pending' }
    error_code { 'MyString' }
    error_description { 'MyText' }
    sent_at { '2025-08-16 10:17:25' }
    delivered_at { '2025-08-16 10:17:25' }
    read_at { '2025-08-16 10:17:25' }
  end
end
