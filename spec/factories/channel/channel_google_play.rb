# frozen_string_literal: true

FactoryBot.define do
  factory :channel_google_play, class: 'Channel::GooglePlay' do
    account
    sequence(:app_id) { |n| "com.example.app#{n}" }
    provider_config do
      {
        'access_token' => SecureRandom.hex(16),
        'refresh_token' => SecureRandom.hex(16),
        'expires_on' => 1.hour.from_now.utc.to_s
      }
    end

    after(:create) do |channel|
      create(:inbox, channel: channel, account: channel.account)
    end
  end
end
