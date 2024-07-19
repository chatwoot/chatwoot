class Digitaltolk::StoreConversationsParquetJob < ApplicationJob
  queue_as :default

  def perform(conversation_ids, file_name)
    @conversations = Conversation.where(id: conversation_ids)

    if @conversations.present?
      Digitaltolk::ConversationsParquetService.new(@conversations, file_name).perform
    end
  end
end