class Channel::MobileApp < ApplicationRecord
  include Channelable
  include FlagShihTzu
  include CustomerChatChannel

  self.table_name = 'channel_mobile_apps'
  EDITABLE_ATTRS = CustomerChatChannel::CHAT_ATTRIBUTES

  def name
    'Mobile app'
  end
end
