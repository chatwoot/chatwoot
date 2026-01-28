class Migration::BackfillConversationCachedMessageIdsJob < ApplicationJob
  queue_as :low

  def perform
    Conversation.find_in_batches(batch_size: 1000) do |conversations|
      conversations.each do |conversation|
        updates = {}

        last_message = conversation.messages.reorder(created_at: :desc).first
        updates[:last_message_id] = last_message&.id

        last_incoming = conversation.messages.incoming.reorder(created_at: :desc).first
        updates[:last_incoming_message_id] = last_incoming&.id

        last_non_activity = conversation.messages.where.not(message_type: :activity).reorder(created_at: :desc).first
        updates[:last_non_activity_message_id] = last_non_activity&.id

        conversation.update_columns(updates)
      end
    end
  end
end
