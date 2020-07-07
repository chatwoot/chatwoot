FactoryBot.define do
  factory :integrations_hook, class: 'Integrations::Hook' do
    status { 1 }
    inbox_id { 1 }
    account_id { 1 }
    app_id { 'slack' }
    settings { 'MyText' }
    hook_type { 1 }
    access_token { SecureRandom.hex }
    reference_id { SecureRandom.hex }
  end
end
