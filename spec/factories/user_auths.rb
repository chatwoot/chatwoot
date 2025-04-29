FactoryBot.define do
  factory :user_auth do
    user
    refresh_token { 'refresh_token_test' }
    access_token { 'access_token_test' }
    client_id { 'client_id_test' }
    client_secret { 'client_secret_test' }
    expiration_datetime { 2_592_000.seconds.from_now }
    tenant_id { 'tenant_id_test' }
  end
end
