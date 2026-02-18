# frozen_string_literal: true

FactoryBot.define do
  factory :channel_x, class: 'Channel::X' do
    account
    profile_id { SecureRandom.hex(8) }
    username { "user_#{SecureRandom.hex(4)}" }
    profile_image_url { Faker::Internet.url }
    bearer_token { SecureRandom.hex(32) }
    refresh_token { SecureRandom.hex(32) }
    token_expires_at { 2.hours.from_now }
    refresh_token_expires_at { 6.months.from_now }

    before :create do |_channel|
      # Stub X API webhook setup calls
      WebMock::API.stub_request(:post, %r{api\.x\.com/2/webhooks})
                  .to_return(status: 200, body: { data: { id: 'webhook_123' } }.to_json, headers: { 'Content-Type' => 'application/json' })
      WebMock::API.stub_request(:post, %r{api\.x\.com/2/account_activity/webhooks/.*/subscriptions})
                  .to_return(status: 204, body: '', headers: {})
    end

    after(:create) do |channel|
      create(:inbox, channel: channel, account: channel.account)
    end
  end
end
