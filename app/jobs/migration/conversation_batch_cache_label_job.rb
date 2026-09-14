class Migration::ConversationBatchCacheLabelJob < ApplicationJob
  queue_as :async_database_migration

  # Reading labels no longer writes their cache on save. Rebuild it explicitly
  # from the taggings, under a lock so a concurrent label edit cannot make it stale.
  def perform(conversation_batch)
    conversation_batch.each do |conversation|
      conversation.with_lock do
        labels = conversation.labels.pluck(:name)
        conversation.update!(cached_label_list: labels.join("#{ActsAsTaggableOn.delimiter} "))
      end
    end
  end
end
