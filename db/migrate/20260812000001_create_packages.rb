class CreatePackages < ActiveRecord::Migration[7.1]
  def change
    create_table :packages do |t|
      t.string :name, null: false
      t.text :description
      t.integer :status, null: false, default: 0
      t.integer :conversations_limit
      t.integer :contacts_limit
      t.integer :users_limit
      t.integer :channels_limit
      t.integer :campaign_messages_limit

      t.timestamps
    end
    add_index :packages, :status
  end
end
