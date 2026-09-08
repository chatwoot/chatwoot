class AddSingleLogoutToAccountSamlSettings < ActiveRecord::Migration[7.1]
  def change
    add_column :account_saml_settings, :sls_url, :string
    add_column :account_saml_settings, :sp_certificate, :text
    add_column :account_saml_settings, :sp_private_key, :text
  end
end
