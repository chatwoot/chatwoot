FactoryBot.define do
  factory :integrations_app_inbox, class: 'Integrations::AppInbox' do
    status { 1 }
    inbox_id { 1 }
    account_id { 1 }
    app_id { 'cw_slack' }
    settings { 'MyText' }
  end
end
