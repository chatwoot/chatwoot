class CreateChatbots < ActiveRecord::Migration[7.0]
  def change
    create_table :chatbots do |t|
      t.string :account_id, null: false, default: 0
      t.string :status
      t.string :name, null: false
      t.integer :inbox_id
      t.string :inbox_name
      t.datetime :last_trained_at
      t.string :website_token
      t.float :temperature, default: 0.1

      t.timestamps
    end

    add_index :chatbots, :account_id
  end
end
