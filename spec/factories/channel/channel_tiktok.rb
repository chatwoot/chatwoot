# frozen_string_literal: true

FactoryBot.define do
  factory :channel_tiktok, class: 'Channel::Tiktok' do
    account
    business_id { SecureRandom.hex(16) }
    access_token { SecureRandom.hex(32) }
    refresh_token { SecureRandom.hex(32) }
    expires_at { 1.day.from_now }
    refresh_token_expires_at { 30.days.from_now }

    after(:create) do |channel|
      create(:inbox, channel: channel, account: channel.account)
    end
  end
end
