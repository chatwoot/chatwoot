class GeocoderMaxmindGeoliteCountry < ActiveRecord::Migration<%= migration_version %>
  def self.up
    create_table :maxmind_geolite_country, id: false do |t|
      t.column :start_ip, :string
      t.column :end_ip, :string
      t.column :start_ip_num, :bigint, null: false
      t.column :end_ip_num, :bigint, null: false
      t.column :country_code, :string, null: false
      t.column :country, :string, null: false
    end
    add_index :maxmind_geolite_country, :start_ip_num, unique: true
  end

  def self.down
    drop_table :maxmind_geolite_country
  end
end
