class AddCachedLabelsList < ActiveRecord::Migration[7.0]
  def change
    add_column :conversations, :cached_label_list, :string
    Conversation.reset_column_information

    if defined?(ActsAsTaggableOn::Taggable::Cache)
      ActsAsTaggableOn::Taggable::Cache.included(Conversation)
    elsif defined?(ActsAsTaggableOn::Taggable::CacheKeys)
      ActsAsTaggableOn::Taggable::CacheKeys.included(Conversation)
    else
      Rails.logger.warn("ActsAsTaggableOn cache module not found, skipping cache inclusion for Conversation")
    end
  end
end
