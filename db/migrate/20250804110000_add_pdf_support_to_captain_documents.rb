class AddPdfSupportToCaptainDocuments < ActiveRecord::Migration[7.1]
  def change
    add_column :captain_documents, :content_type, :string
    add_column :captain_documents, :file_size, :bigint

    add_index :captain_documents, :content_type
  end
end
