class CreateAddons < ActiveRecord::Migration[7.1]
  def change
    create_table :addons do |t|
      t.string :name, null: false
      t.text :description
      t.integer :status, null: false, default: 0
      t.bigint :account_id, null: false
      t.bigint :package_id, null: false
      t.integer :users_limit
      t.integer :channels_limit
      t.integer :contacts_limit
      t.integer :conversations_limit
      t.integer :campaign_messages_limit
      t.datetime :starts_at, null: false
      t.datetime :ends_at, null: false

      t.timestamps
    end
    add_index :addons, :account_id
    add_index :addons, :package_id
    add_index :addons, :status
    add_index :addons, [:account_id, :ends_at]
  end
end
