class AddPendingDataImportItemsIndex < ActiveRecord::Migration[7.1]
  disable_ddl_transaction!

  def change
    add_index :data_import_items, [:data_import_id, :id], where: 'status = 0',
                                                          name: 'index_pending_data_import_items', algorithm: :concurrently
  end
end
