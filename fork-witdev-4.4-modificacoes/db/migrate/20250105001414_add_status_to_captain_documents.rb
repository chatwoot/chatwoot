class AddStatusToCaptainDocuments < ActiveRecord::Migration[7.0]
  def change
    add_column :captain_documents, :status, :integer, null: false, default: 0
    add_index :captain_documents, :status
  end
end
