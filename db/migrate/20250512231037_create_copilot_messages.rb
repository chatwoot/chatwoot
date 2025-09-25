class CreateCopilotMessages < ActiveRecord::Migration[7.0]
  def change
    create_table :copilot_messages do |t|
      t.references :copilot_thread, null: false, index: true
      t.references :user, null: false, index: true
      t.references :account, null: false, index: true
      t.string :message_type, null: false
      t.jsonb :message, null: false, default: {}

      t.timestamps
    end
  end
end
