class AddEncryptionFieldsToAttachments < ActiveRecord::Migration[7.0]
  def change
    add_column :attachments, :encryption_key, :text
    add_column :attachments, :encrypted, :boolean, default: false
    add_column :attachments, :encryption_algorithm, :string
    add_column :attachments, :file_hash_value, :string
    add_column :attachments, :storage_key_value, :string

    add_index :attachments, :encrypted
    add_index :attachments, :storage_key_value, unique: true
    add_index :attachments, :file_hash_value
  end
end