class CreateChatStatusItems < ActiveRecord::Migration[6.0]
  def change
    create_table :chat_status_items do |t|
      t.string :name
      t.boolean :custom, default: true
      t.references :account, null: false, foreign_key: true

      t.timestamps
    end
  end
end
