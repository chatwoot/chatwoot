FactoryBot.define do
  factory :integrations_hook, class: 'Integrations::Hook' do
    app_id { 'dialogflow' }
    account
    settings { { test: 'test' } }
    status { Integrations::Hook.statuses['enabled'] }
    access_token { SecureRandom.hex }
    reference_id { SecureRandom.hex }

    trait :dialogflow do
      app_id { 'dialogflow' }
      settings { { project_id: 'test', credentials: {}, region: 'global', language_code: 'en-US' } }
    end

    trait :dyte do
      app_id { 'dyte' }
      settings { { account_id: 'account_id', app_id: 'app_id', api_token: 'api_token' } }
    end

    trait :google_translate do
      app_id { 'google_translate' }
      settings { { project_id: 'test', credentials: {} } }
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
