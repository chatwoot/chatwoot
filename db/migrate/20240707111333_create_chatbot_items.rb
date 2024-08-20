class CreateChatbotItems < ActiveRecord::Migration[7.0]
  def change
    create_table :chatbot_items do |t|
      t.integer :chatbot_id, null: false
      t.text :text
      t.float :temperature
      t.jsonb :files, default: {}
      t.jsonb :urls, default: {}

      t.timestamps
    end
  end
end
