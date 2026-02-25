class AddPartialIndexContactAccountId < ActiveRecord::Migration[7.0]
  disable_ddl_transaction!

  def change
    add_index :contacts, [:account_id], where: "(email <> '' OR phone_number <> '' OR identifier <> '')",
                                        name: 'index_resolved_contact_account_id', algorithm: :concurrently
  end
end
