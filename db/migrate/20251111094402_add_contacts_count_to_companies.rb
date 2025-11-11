class AddContactsCountToCompanies < ActiveRecord::Migration[7.1]
  def change
    add_column :companies, :contacts_count, :integer, default: 0, null: false
    reversible do |dir|
      dir.up do
        Company.find_each do |company|
          Company.reset_counters(company.id, :contacts)
        end
      end
    end
  end
end
