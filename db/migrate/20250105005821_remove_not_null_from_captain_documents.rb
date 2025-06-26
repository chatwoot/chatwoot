class RemoveNotNullFromCaptainDocuments < ActiveRecord::Migration[7.0]
  def change
    change_column_null :captain_documents, :name, true
  end
end
