class CreateIntegrationsHooks < ActiveRecord::Migration[6.0]
  def change
    create_table :integrations_hooks do |t|
      t.integer :status, default: 0
      t.integer :inbox_id
      t.integer :account_id
      t.string :app_id
      t.text :settings
      t.integer :hook_type, default: 0
      t.string :reference_id
      t.string :access_token
      t.timestamps
    end
  end
end
