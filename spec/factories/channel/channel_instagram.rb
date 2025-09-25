FactoryBot.define do
  factory :channel_instagram, class: 'Channel::Instagram' do
    account
    access_token { SecureRandom.hex(32) }
    instagram_id { SecureRandom.hex(16) }
    expires_at { 60.days.from_now }
    updated_at { 25.hours.ago }

    before :create do |channel|
      WebMock::API.stub_request(:post, "https://graph.instagram.com/v22.0/#{channel.instagram_id}/subscribed_apps")
                  .with(query: {
                          access_token: channel.access_token,
                          subscribed_fields: %w[messages message_reactions messaging_seen]
                        })
                  .to_return(status: 200, body: '', headers: {})

      WebMock::API.stub_request(:delete, "https://graph.instagram.com/v22.0/#{channel.instagram_id}/subscribed_apps")
                  .with(query: {
                          access_token: channel.access_token
                        })
                  .to_return(status: 200, body: '', headers: {})
    end

    after(:create) do |channel|
      create(:inbox, channel: channel, account: channel.account)
    end
  end
end
