class WahaSendMessageJob < ApplicationJob
  queue_as :default

  def perform(message_id)
    message = Message.find(message_id)
    Waha::SendOnChannelService.new(message: message).perform
  end
end