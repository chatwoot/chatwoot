class AddPdfSupportToCaptainDocuments < ActiveRecord::Migration[7.1]
  def change
    add_column :captain_documents, :source_type, :string, default: 'url'

    add_index :captain_documents, :source_type
  end
end