# == Schema Information
#
# Table name: channel_notifica_me
#
#  id            :bigint           not null, primary key
#  channel_token :string           not null
#  channel_type  :string           not null
#  name          :string           not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  account_id    :integer          not null
#  channel_id    :string           not null
#
# Indexes
#
#  index_channel_notifica_me  (channel_id,channel_type,channel_token) UNIQUE
#

class Channel::NotificaMe < ApplicationRecord
  include Channelable

  self.table_name = 'channel_notifica_me'
  EDITABLE_ATTRS = [:channel_id, :channel_type, :channel_token].freeze

  validates :channel_id, presence: true
  validates :channel_type, presence: true
  validates :channel_token, presence: true
  validates :channel_id, uniqueness: { scope: :account_id }

  def name
    'NotificaMe'
  end
end
