# == Schema Information
#
# Table name: channel_tiktok
#
#  id                       :bigint           not null, primary key
#  access_token             :string           not null
#  expires_at               :datetime         not null
#  refresh_token            :string           not null
#  refresh_token_expires_at :datetime         not null
#  created_at               :datetime         not null
#  updated_at               :datetime         not null
#  account_id               :integer          not null
#  business_id              :string           not null
#
# Indexes
#
#  index_channel_tiktok_on_business_id  (business_id) UNIQUE
#
class Channel::Tiktok < ApplicationRecord
  include Channelable
  include Reauthorizable
  self.table_name = 'channel_tiktok'

  # TODO: Remove guard once encryption keys become mandatory (target 3-4 releases out).
  if Chatwoot.encryption_configured?
    encrypts :access_token
    encrypts :refresh_token
  end

  AUTHORIZATION_ERROR_THRESHOLD = 1

  validates :business_id, uniqueness: true, presence: true
  validates :access_token, presence: true
  validates :refresh_token, presence: true
  validates :expires_at, presence: true
  validates :refresh_token_expires_at, presence: true

  def name
    'Tiktok'
  end

  def validated_access_token
    Tiktok::TokenService.new(channel: self).access_token
  end
end
