class IndexImprovementsConversationsContacts < ActiveRecord::Migration[7.0]
  disable_ddl_transaction!

  def change
    remove_index :conversations, :last_activity_at
    add_index :contacts, [:account_id, :last_activity_at],
              order: { last_activity_at: 'DESC NULLS LAST' },
              algorithm: :concurrently,
              name: 'index_contacts_on_account_id_and_last_activity_at'
  end
end
