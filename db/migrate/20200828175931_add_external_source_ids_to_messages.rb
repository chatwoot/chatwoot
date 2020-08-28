class AddExternalSourceIdsToMessages < ActiveRecord::Migration[6.0]
  def change
    add_column :messages, :external_source_ids, :jsonb, default: {}
    migrate_slack_external_source_ids
  end

  def migrate_slack_external_source_ids
    Message.where('source_id LIKE ?', 'slack_%').find_in_batches do |message_batch|
      message_batch.each do |message|
        message.external_source_id_slack = message.source_id.split('slack_')[1]
        message.source_id = nil
        message.save!
      end
    end
  end
end
