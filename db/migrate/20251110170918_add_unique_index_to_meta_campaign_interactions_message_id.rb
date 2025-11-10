class AddUniqueIndexToMetaCampaignInteractionsMessageId < ActiveRecord::Migration[7.1]
  def up
    # Remove duplicate interactions, keeping only the oldest one for each message_id
    execute <<-SQL
      DELETE FROM meta_campaign_interactions
      WHERE id NOT IN (
        SELECT MIN(id)
        FROM meta_campaign_interactions
        GROUP BY message_id
      )
    SQL

    remove_index :meta_campaign_interactions, :message_id
    add_index :meta_campaign_interactions, :message_id, unique: true
  end

  def down
    remove_index :meta_campaign_interactions, :message_id
    add_index :meta_campaign_interactions, :message_id
  end
end
