class AddUniqueIndexToCompaniesDomain < ActiveRecord::Migration[7.1]
  def up
    remove_index :companies, name: 'index_companies_on_domain_and_account_id', if_exists: true

    add_index :companies, [:account_id, :domain],
              unique: true,
              name: 'index_companies_on_account_and_domain',
              where: 'domain IS NOT NULL'
  end

  def down
    remove_index :companies, name: 'index_companies_on_account_and_domain', if_exists: true
    add_index :companies, [:domain, :account_id],
              name: 'index_companies_on_domain_and_account_id'
  end
end
