# frozen_string_literal: true

FactoryBot.define do
  factory :channel_twitter_profile, class: 'Channel::TwitterProfile' do
    twitter_access_token { SecureRandom.uuid }
    twitter_access_token_secret { SecureRandom.uuid }
    profile_id { SecureRandom.uuid }
    account
  end
end
