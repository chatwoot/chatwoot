class UpdateContactInboxForeignKey < ActiveRecord::Migration[6.1]
  def change
    remove_foreign_key :contact_inboxes, :contacts
    add_foreign_key :contact_inboxes, :contacts, on_delete: :cascade

    remove_foreign_key :contact_inboxes, :inboxes
    add_foreign_key :contact_inboxes, :inboxes, on_delete: :cascade

    remove_foreign_key :conversations, :contact_inboxes
    add_foreign_key :conversations, :contact_inboxes, on_delete: :cascade
  end
end
