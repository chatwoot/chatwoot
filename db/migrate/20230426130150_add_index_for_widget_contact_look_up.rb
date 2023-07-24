class AddIndexForWidgetContactLookUp < ActiveRecord::Migration[6.1]
  disable_ddl_transaction!

  def change
    add_index :contacts, 'LOWER(email), account_id', name: 'index_contacts_on_lower_email_account_id', algorithm: :concurrently
  end
end
