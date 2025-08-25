class CreateSamlRoleMappings < ActiveRecord::Migration[7.1]
  def change
    create_table :saml_role_mappings do |t|
      t.references :account_saml_settings, null: false
      t.string :saml_group_name, null: false
      t.integer :role, default: 0, null: false
      t.references :custom_role, null: true

      t.timestamps
    end
  end
end
