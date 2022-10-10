# == Schema Information
#
# Table name: channel_xmpp
#
#  id          :bigint           not null, primary key
#  jid         :string           not null
#  password    :string           not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  account_id  :bigint
#  last_mam_id :string
#
# Indexes
#
#  index_channel_xmpp_on_account_id  (account_id)
#

class Channel::Xmpp < ApplicationRecord
  include Channelable
  include Reauthorizable

  AUTHORIZATION_ERROR_THRESHOLD = 3

  self.table_name = 'channel_xmpp'
  EDITABLE_ATTRS = [:jid, :password].freeze

  after_commit :notify_xmpp_worker

  def name
    'XMPP'
  end

  protected

  def notify_xmpp_worker
    return unless jid_previously_changed? || password_previously_changed?

    ::Redis::Alfred.lpush('xmpp_outbound', {
      channel_id: id,
      _channel_update: true
    }.to_json)
  end
end
