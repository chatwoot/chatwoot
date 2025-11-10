class AddDismissedAtToBulkProcessingRequests < ActiveRecord::Migration[7.1]
  def change
    add_column :bulk_processing_requests, :dismissed_at, :datetime
  end
end
