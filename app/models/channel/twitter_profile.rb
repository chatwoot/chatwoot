# == Schema Information
#
# Table name: channel_twitter_profiles
#
#  id                          :bigint           not null, primary key
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

class Channel::TwitterProfile < ApplicationRecord
  self.table_name = 'channel_twitter_profiles'

  validates :account_id, presence: true
  validates :profile_id, uniqueness: { scope: :account_id }
  belongs_to :account

  has_one :inbox, as: :channel, dependent: :destroy

  before_destroy :unsubscribe

  def create_contact_inbox(profile_id, name, additional_attributes)
    ActiveRecord::Base.transaction do
      contact = inbox.account.contacts.create!(additional_attributes: additional_attributes, name: name)
      ::ContactInbox.create!(
        contact_id: contact.id,
        inbox_id: inbox.id,
        source_id: profile_id
      )
    rescue StandardError => e
      Rails.logger e
    end
  end

  def twitter_client
    Twitty::Facade.new do |config|
      config.consumer_key = ENV.fetch('TWITTER_CONSUMER_KEY', nil)
      config.consumer_secret = ENV.fetch('TWITTER_CONSUMER_SECRET', nil)
      config.access_token = twitter_access_token
      config.access_token_secret = twitter_access_token_secret
      config.base_url = 'https://api.twitter.com'
      config.environment = ENV.fetch('TWITTER_ENVIRONMENT', '')
    end
  end

  private

  def unsubscribe
    webhooks_list = twitter_client.fetch_webhooks.body
    twitter_client.unsubscribe_webhook(id: webhooks_list.first['id']) if webhooks_list.present?
  end
end
