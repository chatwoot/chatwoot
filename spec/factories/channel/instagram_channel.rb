# frozen_string_literal: true

FactoryBot.define do
  factory :channel_instagram_fb_page, class: 'Channel::FacebookPage' do
    page_access_token { SecureRandom.uuid }
    user_access_token { SecureRandom.uuid }
    page_id { SecureRandom.uuid }
    account

    before :create do |_channel|
      WebMock::API.stub_request(:post, 'https://graph.facebook.com/v3.2/me/subscribed_apps')
    end
  end
end
