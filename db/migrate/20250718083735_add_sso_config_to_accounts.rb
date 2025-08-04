class AddSsoConfigToAccounts < ActiveRecord::Migration[7.1]
  def change
    add_column :accounts, :sso_config, :jsonb, default: {}, null: false
    add_index :accounts, :sso_config, using: :gin
  end
end
