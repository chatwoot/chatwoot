class AddCompanyToContacts < ActiveRecord::Migration[7.1]
  def change
    add_reference :contacts, :company, null: true, foreign_key: true
  end
end
