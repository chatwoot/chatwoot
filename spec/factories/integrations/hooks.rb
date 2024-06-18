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
      settings { { api_key: 'api_key' } }
    end
  end
end
