class RemoveOldIndexesFromMessages < ActiveRecord::Migration[7.0]
  def up
    remove_index :messages, name: 'index_messages_on_content', if_exists: true
    remove_index :messages, name: 'index_messages_on_source_id', if_exists: true
  end

  def down
    add_index :messages, :content, using: :gin, opclass: :gin_trgm_ops, name: 'index_messages_on_content' unless index_exists?(:messages, :content, name: 'index_messages_on_content')
    add_index :messages, :source_id, name: 'index_messages_on_source_id' unless index_exists?(:messages, :source_id, name: 'index_messages_on_source_id')
  end
end
