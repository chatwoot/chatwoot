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
      settings { { project_id: 'test', credentials: {} } }
    end

    trait :dyte do
      app_id { 'dyte' }
      settings { { api_key: 'api_key', organization_id: 'org_id' } }
    end

    trait :google_translate do
      app_id { 'google_translate' }
      settings { { project_id: 'test', credentials: {} } }
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
