class CreateIntegrationsSlacks < ActiveRecord::Migration[6.0]
  def change
    create_table :integrations_slacks do |t|
      t.string :client_id
      t.string :client_secret
      t.integer :account_id
      t.timestamps
    end
  end
end
