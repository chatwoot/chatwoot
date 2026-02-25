FactoryBot.define do
  factory :channel_api, class: 'Channel::Api' do
    webhook_url { 'http://example.com' }
    account
    after(:create) do |channel_api|
      create(:inbox, channel: channel_api, account: channel_api.account)
    end
  end
end
