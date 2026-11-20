class AddContactIdAndInboxIdIndexToContactInboxes < ActiveRecord::Migration[8.0]
  disable_ddl_transaction!

  def change
    add_index :contact_inboxes, [:contact_id, :inbox_id],
              name: 'index_contact_inboxes_on_contact_id_and_inbox_id',
              algorithm: :concurrently,
              if_not_exists: true
  end
end
