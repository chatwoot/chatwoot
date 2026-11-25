class AddWhatsappMissingCheckedAtToContactInboxes < ActiveRecord::Migration[7.1]
  def change
    add_column :contact_inboxes, :whatsapp_missing_checked_at, :datetime
  end
end
