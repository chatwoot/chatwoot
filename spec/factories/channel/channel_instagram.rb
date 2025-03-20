FactoryBot.define do
  factory :channel_instagram, class: 'Channel::Instagram' do
    account

    sequence(:instagram_id) { |n| "instagram-id-#{n}" }
    access_token { SecureRandom.uuid }
    expires_at { 1.day.from_now }
    refresh_token { SecureRandom.uuid }

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
