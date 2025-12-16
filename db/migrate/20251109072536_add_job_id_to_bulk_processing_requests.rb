class AddJobIdToBulkProcessingRequests < ActiveRecord::Migration[7.1]
  def change
    add_column :bulk_processing_requests, :job_id, :string
  end
end
