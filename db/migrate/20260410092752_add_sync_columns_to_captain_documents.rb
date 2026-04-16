class AddSyncColumnsToCaptainDocuments < ActiveRecord::Migration[7.0]
  def change
    change_table :captain_documents, bulk: true do |t|
      t.integer :sync_status
      t.datetime :last_synced_at
      t.datetime :last_sync_attempted_at
    end

    add_index :captain_documents, [:account_id, :sync_status]
  end
end
