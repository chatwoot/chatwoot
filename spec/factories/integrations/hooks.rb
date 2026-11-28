FactoryBot.define do
  factory :integrations_hook, class: 'Integrations::Hook' do
    app_id { 'slack' }
    account
    settings { { test: 'test' } }
    status { Integrations::Hook.statuses['enabled'] }
    access_token { SecureRandom.hex }
    reference_id { SecureRandom.hex }

    trait :dialogflow do
      app_id { 'dialogflow' }
      settings do
        {
          project_id: 'test',
          credentials: {
            type: 'service_account', project_id: 'test', client_email: 'dialogflow@test.iam.gserviceaccount.com', private_key: 'test-key'
          },
          region: 'global',
          language_code: 'en-US'
        }
      end
    end

    trait :dyte do
      app_id { 'dyte' }
      settings { { account_id: 'account_id', app_id: 'app_id', api_token: 'api_token' } }
    end

    trait :google_translate do
      app_id { 'google_translate' }
      settings do
        {
          project_id: 'test',
          credentials: {
            type: 'service_account', project_id: 'test', client_email: 'translate@test.iam.gserviceaccount.com', private_key: 'test-key'
          }
        }
      end
    end

    trait :openai do
      app_id { 'openai' }
      settings { { api_key: 'api_key' } }
    end

    trait :linear do
      app_id { 'linear' }
      access_token { SecureRandom.hex }
    end

    trait :shopify do
      app_id { 'shopify' }
      access_token { SecureRandom.hex }
      reference_id { 'test-store.myshopify.com' }
    end

    trait :leadsquared do
      app_id { 'leadsquared' }
      settings do
        {
          'access_key' => SecureRandom.hex,
          'secret_key' => SecureRandom.hex,
          'endpoint_url' => 'https://api.leadsquared.com/'
        }
      end
    end
  end
end
