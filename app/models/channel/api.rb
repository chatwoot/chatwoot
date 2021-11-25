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
  include Channelable

  self.table_name = 'channel_api'
  EDITABLE_ATTRS = [:webhook_url].freeze

  has_secure_token :identifier
  has_secure_token :hmac_token

  def name
    'API'
  end
end
