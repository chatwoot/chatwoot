class AddCachedLabelsList < ActiveRecord::Migration[7.0]
  def change
    add_column :conversations, :cached_label_list, :string
    Conversation.reset_column_information
    ActsAsTaggableOn::Taggable::Cache.included(Conversation)

    update_exisiting_conversations
  end

  private

  def update_exisiting_conversations
    ::Account.find_in_batches do |account_batch|
      account_batch.each do |account|
        Migration::ConversationCacheLabelJob.perform_later(account)
      end
    end
  end
end
