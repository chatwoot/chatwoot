FactoryBot.define do
  factory :channel_sms, class: 'Channel::Sms' do
    sequence(:phone_number) { |n| "+123456789#{n}1" }
    account
    provider_config { { 'api_key' => 'test_key' } }

    after(:create) do |channel_sms|
      create(:inbox, channel: channel_sms, account: channel_sms.account)
    end
  end
end
