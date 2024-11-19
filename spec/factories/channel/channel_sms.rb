FactoryBot.define do
  factory :channel_sms, class: 'Channel::Sms' do
    sequence(:phone_number) { |n| "+123456789#{n}1" }
    account
    provider_config do
      { 'account_id' => '1',
        'application_id' => '1',
        'api_key' => '1',
        'api_secret' => '1' }
    end

    after(:create) do |channel_sms|
      create(:inbox, channel: channel_sms, account: channel_sms.account)
    end
  end
end
