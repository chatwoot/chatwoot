class PreventOverlappingFailedEmailRetryBatches < ActiveRecord::Migration[7.1]
  def change
    add_index :failed_email_retry_batches,
              '(1)',
              unique: true,
              where: 'status IN (0, 1)',
              name: 'index_failed_email_retry_batches_on_active_status'
  end
end
