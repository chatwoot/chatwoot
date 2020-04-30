class CreateIntegrationsAppInboxes < ActiveRecord::Migration[6.0]
  def change
    create_table :integrations_app_inboxes do |t|
      t.integer :status, default: 0
      t.integer :inbox_id
      t.integer :account_id
      t.string :app_id
      t.text :settings

      t.timestamps
    end
  end
end
