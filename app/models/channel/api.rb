# == Schema Information
#
# Table name: channel_api
#
#  id             :bigint           not null, primary key
#  hmac_mandatory :boolean          default(FALSE)
#  hmac_token     :string
#  identifier     :string
#  webhook_url    :string
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  account_id     :integer          not null
#
# Indexes
#
#  index_channel_api_on_hmac_token  (hmac_token) UNIQUE
#  index_channel_api_on_identifier  (identifier) UNIQUE
#

class Channel::Api < ApplicationRecord
  self.table_name = 'channel_api'
  EDITABLE_ATTRS = [:webhook_url].freeze

  validates :account_id, presence: true
  belongs_to :account

  has_secure_token :identifier
  has_secure_token :hmac_token

  has_one :inbox, as: :channel, dependent: :destroy

  def name
    'API'
  end

  def has_24_hour_messaging_window?
    false
  end
end
