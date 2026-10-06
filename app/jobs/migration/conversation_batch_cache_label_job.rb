class Migration::ConversationBatchCacheLabelJob < ApplicationJob
  queue_as :async_database_migration

  # This job fills cached_label_list for conversations that were labelled before the column existed.
  #
  # It used to read label_list and call save!. That worked because acts-as-taggable-on wrote
  # the label cache on every save once the list had been read.
  # Reference: https://github.com/mbleigh/acts-as-taggable-on/wiki/Caching
  #
  # Labelable::Persistence now skips that write when the list was only read, because it let
  # a stale record overwrite labels saved elsewhere. With that guard, read-then-save leaves
  # the cache empty. So this job builds the cache from the taggings and writes it directly.
  def perform(conversation_batch)
    conversation_batch.each do |conversation|
      conversation.update!(cached_label_list: conversation.labels.pluck(:name).join("#{ActsAsTaggableOn.delimiter} "))
    end
  end
end
