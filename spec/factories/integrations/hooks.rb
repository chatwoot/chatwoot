FactoryBot.define do
  factory :integrations_hook, class: 'Integrations::Hook' do
    status { Integrations::Hook.statuses['enabled'] }
    inbox
    account
    app_id { 'slack' }
    settings { { 'test': 'test' } }
    hook_type { Integrations::Hook.statuses['account'] }
    access_token { SecureRandom.hex }
    reference_id { SecureRandom.hex }
  end
end
