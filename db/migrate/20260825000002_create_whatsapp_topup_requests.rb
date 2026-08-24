# frozen_string_literal: true

class CreateWhatsappTopupRequests < ActiveRecord::Migration[7.1]
  def change
    create_table :whatsapp_topup_requests do |t|
      t.references :account, null: false, foreign_key: { on_delete: :cascade }
      t.references :user, null: false, foreign_key: { on_delete: :cascade }
      t.integer :credits, null: false
      t.integer :status, null: false, default: 0

      t.timestamps
    end

    add_index :whatsapp_topup_requests, [:account_id, :status]
  end
end
