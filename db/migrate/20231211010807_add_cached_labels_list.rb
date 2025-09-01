# db/migrate/20231211010807_add_cached_labels_list.rb
class AddCachedLabelsList < ActiveRecord::Migration[7.1]
  def change
    # Add a cached label list to the models Chatwoot labels (usually conversations & contacts)
    add_column :conversations, :cached_label_list, :text unless column_exists?(:conversations, :cached_label_list)
    add_column :contacts,      :cached_label_list, :text unless column_exists?(:contacts,      :cached_label_list)

    # Optional: add trigram indexes if you use fuzzy search on cached lists (Postgres)
    enable_extension 'pg_trgm' unless extension_enabled?('pg_trgm')
    unless index_name_exists?(
      :conversations, 'idx_conversations_cached_label_list_gin'
    )
      add_index :conversations, :cached_label_list, using: :gin, name: 'idx_conversations_cached_label_list_gin',
                                                    opclass: :gin_trgm_ops
    end
    unless index_name_exists?(
      :contacts, 'idx_contacts_cached_label_list_gin'
    )
      add_index :contacts,      :cached_label_list, using: :gin, name: 'idx_contacts_cached_label_list_gin',
                                                    opclass: :gin_trgm_ops
    end
  end
end
