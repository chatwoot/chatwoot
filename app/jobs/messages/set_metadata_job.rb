class Messages::SetMetadataJob < ApplicationJob
  queue_as :high

  def perform(id)
    message = Message.find(id)
    return unless message.shopee_card?

    Messages::LoadShopeeDataService.new(message: message).perform
  end
end
