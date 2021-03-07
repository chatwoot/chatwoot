class CreateConversationStatuses < ActiveRecord::Migration[6.0]
  def change
    create_table :conversation_statuses do |t|
      t.string :name
      t.boolean :custom, default: false
      t.integer :code
      t.references :account, null: false, foreign_key: true

      t.timestamps
    end
  end
end
