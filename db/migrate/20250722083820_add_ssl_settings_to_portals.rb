class AddSslSettingsToPortals < ActiveRecord::Migration[7.1]
  def change
    add_column :portals, :ssl_settings, :jsonb, default: {}, null: false
  end
end
