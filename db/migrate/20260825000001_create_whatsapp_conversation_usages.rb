# frozen_string_literal: true

class CreateWhatsappConversationUsages < ActiveRecord::Migration[7.1]
  def change
    create_table :whatsapp_conversation_usages do |t|
      t.references :account, null: false, foreign_key: { on_delete: :cascade }
      t.references :inbox, null: false, foreign_key: { on_delete: :cascade }
      t.references :conversation, null: false, foreign_key: { on_delete: :cascade }
      t.references :message, null: false, foreign_key: { on_delete: :cascade }

      t.datetime :created_at, null: false
    end

    add_index :whatsapp_conversation_usages, [:account_id, :created_at]
  end
end
