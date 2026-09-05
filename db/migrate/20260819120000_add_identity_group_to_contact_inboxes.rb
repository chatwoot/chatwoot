class AddIdentityGroupToContactInboxes < ActiveRecord::Migration[7.1]
  disable_ddl_transaction!

  # Records which contact inboxes one webhook proved belong to the same person. Meta answers that
  # question per event and never sends a stable group identifier, so the answer only exists at the
  # moment a payload arrives and Chatwoot currently has nowhere to keep it.
  def change
    add_column :contact_inboxes, :identity_group_id, :uuid

    add_index :contact_inboxes, :identity_group_id,
              name: 'index_contact_inboxes_on_identity_group_id',
              algorithm: :concurrently,
              if_not_exists: true
  end
end
