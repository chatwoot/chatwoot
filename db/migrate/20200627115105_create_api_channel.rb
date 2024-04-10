class CreateApiChannel < ActiveRecord::Migration[6.0]
  def change
    create_table :channel_api do |t|
      t.integer :account_id, null: false
      t.string :webhook_url, null: false
      t.timestamps
    end
  end
end
