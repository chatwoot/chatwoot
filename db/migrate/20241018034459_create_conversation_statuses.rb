class CreateConversationStatuses < ActiveRecord::Migration[7.0]
  def change
    create_table :conversation_statuses do |t|
      t.references :account, null: false, index: true
      t.references :inbox, null: false, index: true
      t.references :conversation, null: false, index: true
      t.integer :status, null: false

      t.index [:conversation_id, :created_at]
      t.timestamps
    end
  end
end
