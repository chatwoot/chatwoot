FactoryBot.define do
  factory :channel_twilio_sms, class: 'Channel::TwilioSms' do
    auth_token { SecureRandom.uuid }
    account_sid { SecureRandom.uuid }
    messaging_service_sid { "MG#{Faker::Number.hexadecimal(digits: 32)}" }
    medium { :sms }
    account
    after(:build) do |channel|
      channel.inbox ||= create(:inbox, account: channel.account)
    end

    trait :with_phone_number do
      sequence(:phone_number) { |n| "+123456789#{n}1" }
      messaging_service_sid { nil }
    end

    trait :whatsapp do
      medium { :whatsapp }
    end

    trait :with_voice do
      with_phone_number
      voice_enabled { true }
      api_key_sid { "SK#{SecureRandom.hex(16)}" }
      api_key_secret { SecureRandom.hex(16) }
      twiml_app_sid { "AP#{SecureRandom.hex(16)}" }
    end
  end
end
