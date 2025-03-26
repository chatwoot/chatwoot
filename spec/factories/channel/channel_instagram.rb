FactoryBot.define do
  factory :channel_instagram, class: 'Channel::Instagram' do
    account
    access_token { SecureRandom.hex(32) }
    instagram_id { SecureRandom.hex(16) }
    expires_at { 60.days.from_now }
    updated_at { 25.hours.ago }

    after(:create) do |channel|
      create(:inbox, channel: channel, account: channel.account)
    end
  end
end
