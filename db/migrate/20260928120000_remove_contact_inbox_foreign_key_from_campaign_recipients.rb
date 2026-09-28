class RemoveContactInboxForeignKeyFromCampaignRecipients < ActiveRecord::Migration[7.1]
  def up
    remove_foreign_key :campaign_recipients, :contact_inboxes, if_exists: true
  end

  def down; end
end
