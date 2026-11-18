class AddMetadataUrlToAccountSamlSettings < ActiveRecord::Migration[7.2]
  def change
    add_column :account_saml_settings, :metadata_url, :string
    add_column :account_saml_settings, :metadata_refreshed_at, :datetime
  end
end
