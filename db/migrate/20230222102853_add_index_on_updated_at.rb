class AddIndexOnUpdatedAt < ActiveRecord::Migration[6.1]
  def change
    add_index :pg_search_documents, :updated_at
  end
end
