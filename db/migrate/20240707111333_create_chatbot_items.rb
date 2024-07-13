class CreateChatbotItems < ActiveRecord::Migration[7.0]
  def change
    create_table :chatbot_items do |t|
      t.integer :chatbot_id, null: false
      t.text :bot_text
      t.float :temperature
      t.jsonb :bot_files, default: {}
      t.jsonb :bot_urls, default: {}

      t.timestamps
    end
  end
end
