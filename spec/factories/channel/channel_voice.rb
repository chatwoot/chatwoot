# frozen_string_literal: true

FactoryBot.define do
  factory :channel_voice, class: 'Channel::Voice' do
    sequence(:phone_number) { |n| "+155512345#{n.to_s.rjust(2, '0')}" }
    provider_config do
      {
        account_sid: "AC#{SecureRandom.hex(16)}",
        auth_token: SecureRandom.hex(16),
        api_key_sid: SecureRandom.hex(8),
        api_key_secret: SecureRandom.hex(16),
        twiml_app_sid: "AP#{SecureRandom.hex(16)}"
      }
    end
    account

    after(:create) do |channel_voice|
      create(:inbox, channel: channel_voice, account: channel_voice.account)
    end
  end
end
