class AddContactInboxToCampaignRecipients < ActiveRecord::Migration[7.1]
  def change
    add_reference :campaign_recipients, :contact_inbox, foreign_key: { on_delete: :nullify }
  end
end
