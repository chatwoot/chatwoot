# frozen_string_literal: true

# == Schema Information
#
# Table name: channel_twitter_profiles
#
#  id                          :bigint           not null, primary key
#  tweets_enabled              :boolean          default(TRUE)
#  twitter_access_token        :string           not null
#  twitter_access_token_secret :string           not null
#  created_at                  :datetime         not null
#  updated_at                  :datetime         not null
#  account_id                  :integer          not null
#  profile_id                  :string           not null
#
# Indexes
#
#  index_channel_twitter_profiles_on_account_id_and_profile_id  (account_id,profile_id) UNIQUE
#
FactoryBot.define do
  factory :channel_twitter_profile, class: 'Channel::TwitterProfile' do
    twitter_access_token { SecureRandom.uuid }
    twitter_access_token_secret { SecureRandom.uuid }
    profile_id { SecureRandom.uuid }
    account
  end
end
