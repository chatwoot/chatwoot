FactoryBot.define do
  factory :channel_whatsapp, class: 'Channel::Whatsapp' do
    sequence(:phone_number) { |n| "+123456789#{n}1" }
    account
    provider_config { { 'api_key' => 'test_key' } }

    after(:create) do |channel_whatsapp|
      create(:inbox, channel: channel_whatsapp, account: channel_whatsapp.account)
    end
  end
end
