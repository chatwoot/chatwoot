class Migration::ConversationCacheLabelJob < ApplicationJob
  queue_as :within_1_day

  def perform(account)
    account.conversations.find_in_batches(batch_size: 100) do |conversation_batch|
      Migration::ConversationBatchCacheLabelJob.perform_later(conversation_batch)
    end
  end
end
