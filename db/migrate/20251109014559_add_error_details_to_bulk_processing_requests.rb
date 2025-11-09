class AddErrorDetailsToBulkProcessingRequests < ActiveRecord::Migration[7.1]
  def change
    add_column :bulk_processing_requests, :error_details, :jsonb, default: []
  end
end
