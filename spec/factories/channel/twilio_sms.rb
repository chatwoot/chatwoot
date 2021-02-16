FactoryBot.define do
  factory :channel_twilio_sms, class: 'Channel::TwilioSms' do
    auth_token { SecureRandom.uuid }
    account_sid { SecureRandom.uuid }
    sequence(:phone_number) { |n| "+123456789#{n}1" }
    medium { :sms }
    account
    after(:build) do |channel|
      channel.inbox ||= create(:inbox, account: channel.account)
    end
  end
end
