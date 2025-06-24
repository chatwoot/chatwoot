class AddDocumentTypeAndExternalIdToCaptainDocuments < ActiveRecord::Migration[7.1]
  def change
    add_column :captain_documents, :document_type, :integer, default: 0, null: false
    add_column :captain_documents, :external_id, :string

    add_index :captain_documents, :document_type
    add_index :captain_documents, [:assistant_id, :external_id, :document_type],
              unique: true,
              name: 'index_captain_documents_unique_external_id'
  end
end
