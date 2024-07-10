class Digitaltolk::StoreMessagesParquetJob  < ApplicationJob
  queue_as :default

  def perform(message_ids, file_name)
    @messages = Message.where(id: message_ids)

    Digitaltolk::MessagesParquetService.new(@messages, file_name).perform
  end
end