class CreateChatbots < ActiveRecord::Migration[7.0]
  def change
    create_table :chatbots do |t|
      t.string :account_id, null: false,  default: 0
      t.boolean :bot_status
      t.string :chatbot_id, null: false
      t.string :chatbot_name
      t.integer :inbox_id
      t.string :inbox_name
      t.datetime :last_trained_at
      t.string :website_token

      t.timestamps
    end
  end
end
