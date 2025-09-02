class CreateAdvancedSearchIndexes < ActiveRecord::Migration[7.0]
  def up
    # Create composite indexes for conversations with most common search combinations
    add_index :conversations, [:account_id, :status, :created_at], 
              name: 'idx_conversations_account_status_created_at'
    
    add_index :conversations, [:account_id, :inbox_id, :status, :assignee_id, :created_at], 
              name: 'idx_conversations_search_filter_combo'
              
    add_index :conversations, [:account_id, :team_id, :status, :created_at], 
              name: 'idx_conversations_account_team_status_created'
              
    add_index :conversations, [:account_id, :priority, :status, :created_at], 
              name: 'idx_conversations_account_priority_status_created'

    # Add GIN index for labels search (if not already exists)
    add_index :conversations, 'to_tsvector(\'english\', COALESCE(cached_label_list, \'\'))', 
              using: :gin, name: 'idx_conversations_labels_fts'

    # Create advanced message search indexes
    add_index :messages, [:account_id, :conversation_id, :message_type, :created_at], 
              name: 'idx_messages_account_conv_type_created'
              
    add_index :messages, [:account_id, :inbox_id, :message_type, :created_at], 
              name: 'idx_messages_account_inbox_type_created'
              
    add_index :messages, [:account_id, :sender_type, :sender_id, :created_at], 
              name: 'idx_messages_account_sender_created'

    # Enhanced full-text search indexes for messages
    execute <<-SQL
      CREATE INDEX CONCURRENTLY idx_messages_content_trgm 
      ON messages USING gin (content gin_trgm_ops) 
      WHERE content IS NOT NULL;
    SQL

    execute <<-SQL
      CREATE INDEX CONCURRENTLY idx_messages_processed_content_trgm 
      ON messages USING gin (processed_message_content gin_trgm_ops) 
      WHERE processed_message_content IS NOT NULL;
    SQL

    # Create composite index for message search with filters
    add_index :messages, [:account_id, :message_type, :private, :created_at], 
              name: 'idx_messages_search_filter_combo'

    # Contact search optimization
    add_index :contacts, [:account_id, :name, :email], 
              name: 'idx_contacts_account_name_email'
    
    execute <<-SQL
      CREATE INDEX CONCURRENTLY idx_contacts_search_trgm 
      ON contacts USING gin (
        (COALESCE(name, '') || ' ' || COALESCE(email, '') || ' ' || COALESCE(phone_number, '') || ' ' || COALESCE(identifier, '')) gin_trgm_ops
      );
    SQL

    # Indexes for additional attributes search (JSON fields)
    add_index :conversations, 'additional_attributes', using: :gin, 
              name: 'idx_conversations_additional_attrs'
              
    add_index :messages, 'additional_attributes', using: :gin, 
              name: 'idx_messages_additional_attrs'

    # Time-based partitioning helpers for large datasets
    add_index :messages, [:created_at, :account_id], 
              name: 'idx_messages_created_at_account'
              
    add_index :conversations, [:created_at, :account_id], 
              name: 'idx_conversations_created_at_account'

    # Custom attributes search
    add_index :conversations, 'custom_attributes', using: :gin, 
              name: 'idx_conversations_custom_attrs'
              
    add_index :contacts, 'custom_attributes', using: :gin, 
              name: 'idx_contacts_custom_attrs'

    # Add statistics collection for better query planning
    execute "ANALYZE conversations, messages, contacts;"
  end

  def down
    remove_index :conversations, name: 'idx_conversations_account_status_created_at'
    remove_index :conversations, name: 'idx_conversations_search_filter_combo'
    remove_index :conversations, name: 'idx_conversations_account_team_status_created'
    remove_index :conversations, name: 'idx_conversations_account_priority_status_created'
    remove_index :conversations, name: 'idx_conversations_labels_fts'
    
    remove_index :messages, name: 'idx_messages_account_conv_type_created'
    remove_index :messages, name: 'idx_messages_account_inbox_type_created'
    remove_index :messages, name: 'idx_messages_account_sender_created'
    remove_index :messages, name: 'idx_messages_search_filter_combo'
    
    execute "DROP INDEX CONCURRENTLY IF EXISTS idx_messages_content_trgm;"
    execute "DROP INDEX CONCURRENTLY IF EXISTS idx_messages_processed_content_trgm;"
    execute "DROP INDEX CONCURRENTLY IF EXISTS idx_contacts_search_trgm;"
    
    remove_index :contacts, name: 'idx_contacts_account_name_email'
    remove_index :conversations, name: 'idx_conversations_additional_attrs'
    remove_index :messages, name: 'idx_messages_additional_attrs'
    remove_index :messages, name: 'idx_messages_created_at_account'
    remove_index :conversations, name: 'idx_conversations_created_at_account'
    remove_index :conversations, name: 'idx_conversations_custom_attrs'
    remove_index :contacts, name: 'idx_contacts_custom_attrs'
  end
end