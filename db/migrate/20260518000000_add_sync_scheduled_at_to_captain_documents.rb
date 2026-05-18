class AddSyncScheduledAtToCaptainDocuments < ActiveRecord::Migration[7.0]
  def change
    add_column :captain_documents, :sync_scheduled_at, :datetime
  end
end
