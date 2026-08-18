FactoryBot.define do
  factory :channel_voice, class: 'Channel::Voice' do
    sequence(:phone_number) { |n| "+199900#{format('%05d', n)}" }
    account

    after(:create) do |channel_voice|
      create(:inbox, channel: channel_voice, account: channel_voice.account)
    end
  end
end
