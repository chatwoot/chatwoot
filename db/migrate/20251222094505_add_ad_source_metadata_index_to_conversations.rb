# frozen_string_literal: true

class AddAdSourceMetadataIndexToConversations < ActiveRecord::Migration[7.0]
  disable_ddl_transaction!

  def up
    # Add GIN index on additional_attributes JSONB field for efficient querying of ad source metadata
    # This helps with filtering and analytics of conversations by ad source
    add_index :conversations, :additional_attributes,
              using: :gin,
              name: 'index_conversations_on_additional_attributes_gin',
              if_not_exists: true,
              algorithm: :concurrently
  end

  def down
    remove_index :conversations, name: 'index_conversations_on_additional_attributes_gin', if_exists: true
  end
end
