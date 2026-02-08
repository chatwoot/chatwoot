class AddStickerIndexesToAttachments < ActiveRecord::Migration[7.1]
  def up
    # Add GIN index for JSONB meta column to optimize sticker queries
    add_index :attachments, :meta, using: :gin, name: 'index_attachments_on_meta_gin'
    
    # Add composite index for common sticker queries - using safer approach
    execute <<-SQL
      CREATE INDEX IF NOT EXISTS index_attachments_on_account_file_type_sticker_type 
      ON attachments (account_id, file_type, (meta->>'sticker_type'))
      WHERE meta->>'sticker_type' IS NOT NULL;
    SQL
    
    # Add index for sticker pack queries
    execute <<-SQL
      CREATE INDEX IF NOT EXISTS index_attachments_on_account_sticker_pack 
      ON attachments (account_id, (meta->>'sticker_pack'))
      WHERE meta->>'sticker_type' = 'custom';
    SQL
    
    # Add index for created_at ordering in sticker queries
    execute <<-SQL
      CREATE INDEX IF NOT EXISTS index_attachments_on_account_created_at_stickers 
      ON attachments (account_id, created_at)
      WHERE meta->>'sticker_type' = 'custom';
    SQL
  end

  def down
    remove_index :attachments, name: 'index_attachments_on_meta_gin'
    remove_index :attachments, name: 'index_attachments_on_account_file_type_sticker_type'
    remove_index :attachments, name: 'index_attachments_on_account_sticker_pack'
    remove_index :attachments, name: 'index_attachments_on_account_created_at_stickers'
  end
end