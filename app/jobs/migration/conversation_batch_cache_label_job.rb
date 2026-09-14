class Migration::ConversationBatchCacheLabelJob < ApplicationJob
  queue_as :async_database_migration

  # To cache the label, we simply access it from the object and save it. Anytime the object is
  # saved in the future, ActsAsTaggable will automatically recompute it. This process is done
  # initially when the user has not performed any action.
  # Reference: https://github.com/mbleigh/acts-as-taggable-on/wiki/Caching
  def perform(conversation_batch)
    conversation_batch.each do |conversation|
      conversation.label_list
      conversation.save!
    end
  end
end
