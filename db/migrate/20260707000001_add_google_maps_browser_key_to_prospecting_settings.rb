class AddGoogleMapsBrowserKeyToProspectingSettings < ActiveRecord::Migration[7.1]
  def change
    add_column :autonomia_prospecting_settings, :google_maps_browser_api_key, :string
  end
end
