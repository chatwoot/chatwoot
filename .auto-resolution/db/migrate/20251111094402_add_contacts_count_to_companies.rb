class AddContactsCountToCompanies < ActiveRecord::Migration[7.1]
  def change
    add_column :companies, :contacts_count, :integer, default: 0, null: false
  end
end
