class AddCompanyNameLookupIndex < ActiveRecord::Migration[8.0]
  disable_ddl_transaction!

  def change
    add_index :companies, 'account_id, lower(name)', name: 'index_companies_on_account_id_and_lower_name', algorithm: :concurrently
  end
end
