class AddGooglePlacesKeyToProspectingSettings < ActiveRecord::Migration[7.1]
  def change
    add_column :autonomia_prospecting_settings, :google_places_api_key, :string
  end
end
