class AddCachedLabelsList < ActiveRecord::Migration[7.0]
  def change
    add_column :conversations, :cached_label_list, :string
    # If you're not sure the following lines work, comment or remove them
    # Conversation.reset_column_information
    # ActsAsTaggableOn::Taggable::Cache.included(Conversation)
  end
end

