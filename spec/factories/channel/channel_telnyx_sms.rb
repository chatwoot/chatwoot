FactoryBot.define do
  factory :channel_telnyx_sms, class: 'Channel::TelnyxSms' do
    sequence(:phone_number) { |n| "+123456780#{n}1" }
    account
    provider_config do
      {
        'api_key' => 'test-api-key',
        'messaging_profile_id' => 'test-messaging-profile-id'
      }
    end

    after(:create) do |channel|
      create(:inbox, channel: channel, account: channel.account)
    end
  end
end
