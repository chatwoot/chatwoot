# == Schema Information
#
# Table name: channel_twilio_sms
#
#  id                             :bigint           not null, primary key
#  account_sid                    :string           not null
#  api_key_sid                    :string
#  auth_token                     :string           not null
#  content_templates              :jsonb
#  content_templates_last_updated :datetime
#  medium                         :integer          default("sms")
#  messaging_service_sid          :string
#  phone_number                   :string
#  created_at                     :datetime         not null
#  updated_at                     :datetime         not null
#  account_id                     :integer          not null
#
# Indexes
#
#  index_channel_twilio_sms_on_account_sid_and_phone_number  (account_sid,phone_number) UNIQUE
#  index_channel_twilio_sms_on_messaging_service_sid         (messaging_service_sid) UNIQUE
#  index_channel_twilio_sms_on_phone_number                  (phone_number) UNIQUE
#
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
  end
end
