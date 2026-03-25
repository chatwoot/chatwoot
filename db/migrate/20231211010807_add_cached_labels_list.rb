class AddCachedLabelsList < ActiveRecord::Migration[7.0]
  def change
    add_column :conversations, :cached_label_list, :string
    Conversation.reset_column_information
    begin
      ActsAsTaggableOn::Taggable::Cache.included(Conversation)
    rescue NameError => e
      Rails.logger.warn "Skipping ActsAsTaggableOn cache initialization: #{e.message}"
    end
  end
end
