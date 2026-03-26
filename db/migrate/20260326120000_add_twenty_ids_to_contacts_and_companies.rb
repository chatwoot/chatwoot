class AddTwentyIdsToContactsAndCompanies < ActiveRecord::Migration[7.1]
  def change
    add_column :contacts, :twenty_id, :string
    add_column :companies, :twenty_id, :string

    add_index :contacts, [:account_id, :twenty_id], unique: true, where: 'twenty_id IS NOT NULL'
    add_index :companies, [:account_id, :twenty_id], unique: true, where: 'twenty_id IS NOT NULL'
  end
end
