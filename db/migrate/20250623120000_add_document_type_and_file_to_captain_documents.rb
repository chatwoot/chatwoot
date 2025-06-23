class AddDocumentTypeAndFileToCaptainDocuments < ActiveRecord::Migration[7.0]
  def change
    add_column :captain_documents, :document_type, :integer, default: 0, null: false
    add_index :captain_documents, :document_type
  end
end