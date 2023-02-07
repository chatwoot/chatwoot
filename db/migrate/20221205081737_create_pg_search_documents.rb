class CreatePgSearchDocuments < ActiveRecord::Migration[6.1]
  def up
    say_with_time('Creating table for pg_search multisearch') do
      create_table :pg_search_documents do |t|
        t.text :content
        t.bigint 'account_id'
        t.belongs_to :searchable, polymorphic: true, index: true
        t.timestamps null: false
      end
      add_index :pg_search_documents, :account_id
      add_index :pg_search_documents, [:searchable_id, :searchable_type], unique: true, name: 'unique_searchables_index'
    end
  end

  def down
    say_with_time('Dropping table for pg_search multisearch') do
      drop_table :pg_search_documents
    end
  end
end
