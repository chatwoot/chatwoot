class AddContactInboxForeignKeyToCampaignRecipients < ActiveRecord::Migration[7.1]
  disable_ddl_transaction!

  def up
    add_foreign_key :campaign_recipients, :contact_inboxes, on_delete: :nullify, validate: false, if_not_exists: true
    validate_foreign_key :campaign_recipients, :contact_inboxes
  end

  def down
    remove_foreign_key :campaign_recipients, :contact_inboxes, if_exists: true
  end
end
