class AddPartialIndexForResolvedContacts < ActiveRecord::Migration[7.0]
  disable_ddl_transaction!

  def change
    add_index :contacts, [:account_id, :email, :phone_number, :identifier], where: "(email <> '' OR phone_number <> '' OR identifier <> '')",
                                                                            name: 'index_contacts_on_nonempty_fields', algorithm: :concurrently
  end
end
