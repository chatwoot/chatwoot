class CreateWebhooks < ActiveRecord::Migration[6.0]
  def change
    create_table :webhooks do |t|
      t.integer :account_id
      t.integer :inbox_id
      t.string :urls

      t.timestamps
    end
  end
end
