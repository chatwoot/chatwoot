class AddGeoLocationToAudits < ActiveRecord::Migration[7.1]
  def change
    add_column :audits, :city, :string
    add_column :audits, :country, :string
    add_column :audits, :country_code, :string
  end
end
