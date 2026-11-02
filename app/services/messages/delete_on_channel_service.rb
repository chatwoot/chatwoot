# Deletes a message for the customer on its channel, for channels that support it.
# Each channel service defines DELETE_WINDOW, how long after sending the channel still allows deleting a message.
# A channel service raises CustomExceptions::ChannelMessageDeleteFailed when the channel refuses.
class Messages::DeleteOnChannelService
  CHANNEL_SERVICES = {
    'Channel::Telegram' => ::Telegram::DeleteMessageService
  }.freeze

  pattr_initialize [:message!]

  # nil when the inbox's channel can't delete messages for the customer
  def self.delete_window(inbox)
    service_class = CHANNEL_SERVICES[inbox.channel_type]
    service_class::DELETE_WINDOW if service_class
  end

  def perform
    CHANNEL_SERVICES[message.inbox.channel_type]&.new(message: message)&.perform
  end
end
