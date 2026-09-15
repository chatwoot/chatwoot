class AddFtsIndexToMessages < ActiveRecord::Migration[7.1]
  disable_ddl_transaction!

  INDEX_NAME = 'index_messages_on_content_fts'.freeze

  def up
    return if index_name_exists?(:messages, INDEX_NAME)

    add_index :messages,
              "to_tsvector('english', content)",
              using: :gin,
              name: INDEX_NAME,
              algorithm: :concurrently
  end

  def down
    return unless index_name_exists?(:messages, INDEX_NAME)

    remove_index :messages, name: INDEX_NAME, algorithm: :concurrently
  end
end
