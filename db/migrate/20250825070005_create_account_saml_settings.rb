class CreateAccountSamlSettings < ActiveRecord::Migration[7.1]
  def change
    create_table :account_saml_settings do |t|
      t.references :account, null: false
      t.string :sso_url
      t.text :certificate
      t.string :sp_entity_id
      t.string :idp_entity_id
      t.json :role_mappings, default: {}

      t.timestamps
    end
  end
end
