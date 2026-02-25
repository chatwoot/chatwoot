class AddMetadataToCaptainDocuments < ActiveRecord::Migration[7.1]
  def change
    add_column :captain_documents, :metadata, :jsonb, default: {}
  end
end
