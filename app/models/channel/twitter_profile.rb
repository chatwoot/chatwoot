# == Schema Information
#
# Table name: channel_twitter_profiles
#
#  id                          :bigint           not null, primary key
#  name                        :string
#  twitter_access_token        :string           not null
#  twitter_access_token_secret :string           not null
#  created_at                  :datetime         not null
#  updated_at                  :datetime         not null
#  account_id                  :integer          not null
#  profile_id                  :string           not null
#

class Channel::TwitterProfile < ApplicationRecord
  self.table_name = 'channel_twitter_profiles'

  validates :account_id, presence: true
  validates :profile_id, uniqueness: { scope: :account_id }
  has_one_attached :avatar
  belongs_to :account

  has_one :inbox, as: :channel, dependent: :destroy

  before_destroy :unsubscribe

  def name
    'Twitter'
  end

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

  private

  def unsubscribe
    # to implement
  end
end
