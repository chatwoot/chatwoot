class AddOperationTypeToBulkProcessingRequests < ActiveRecord::Migration[7.1]
  def change
    add_column :bulk_processing_requests, :operation_type, :string, default: 'UPLOAD'
    add_index :bulk_processing_requests, :operation_type
  end
end
