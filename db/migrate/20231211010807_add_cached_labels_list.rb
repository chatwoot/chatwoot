class AddCachedLabelsList < ActiveRecord::Migration[7.0]
  def change
    add_column :conversations, :cached_label_list, :string
    Conversation.reset_column_information
    begin
      ActsAsTaggableOn::Taggable::Cache.included(Conversation)
    rescue NameError
      begin
        ActsAsTaggableOn::Taggable::CacheKeys.included(Conversation)
      rescue NameError
        # Neither constant exists — column added successfully, skip cache backfill
      end
    end
  end
end
