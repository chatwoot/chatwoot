class AddLocationAndCountryCodeToContacts < ActiveRecord::Migration[7.0]
  def change
    add_column :contacts, :location, :string, default: ''
    add_column :contacts, :country_code, :string, default: ''
  end
end
